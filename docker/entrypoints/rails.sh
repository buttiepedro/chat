#!/bin/sh

rm -rf /app/tmp/pids/server.pid
rm -rf '/app/tmp/cache/*'

# Configurar conexión según si se usa DATABASE_URL o variables individuales
if [ -n "$DATABASE_URL" ]; then
  DB_HOST=$(ruby -r uri -e "print URI('$DATABASE_URL').host" 2>/dev/null || echo "localhost")
  DB_PORT=$(ruby -r uri -e "print URI('$DATABASE_URL').port || 5432" 2>/dev/null || echo "5432")
  DB_USER=$(ruby -r uri -e "print URI('$DATABASE_URL').user" 2>/dev/null || echo "")
  PSQL="psql $DATABASE_URL"
  EXTERNAL_DB=true
else
  DB_HOST=$POSTGRES_HOST
  DB_PORT=${POSTGRES_PORT:-5432}
  DB_USER=$POSTGRES_USERNAME
  export PGPASSWORD=$POSTGRES_PASSWORD
  PSQL="psql -h $DB_HOST -p $DB_PORT -U $DB_USER"
  EXTERNAL_DB=false
fi

echo "Waiting for database..."
until pg_isready -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" 2>/dev/null; do
  sleep 2
done
echo "Database ready."

bundle install

# Crear schema si se especificó uno distinto a public
SCHEMA=${POSTGRES_SCHEMA:-public}
if [ "$SCHEMA" != "public" ]; then
  echo "Creating schema '$SCHEMA' if not exists..."
  $PSQL -c "CREATE SCHEMA IF NOT EXISTS \"$SCHEMA\";" 2>/dev/null || true
  # Setear search_path a nivel de DB para que funcione con PgBouncer
  DB_NAME=$(ruby -r uri -e "print URI(ENV['DATABASE_URL'] || '').path.to_s.sub('/','').split('?')[0]" 2>/dev/null)
  DB_NAME=${DB_NAME:-$POSTGRES_DATABASE}
  echo "Setting database search_path to '$SCHEMA, public'..."
  $PSQL -c "ALTER DATABASE \"$DB_NAME\" SET search_path TO \"$SCHEMA\", public;" 2>/dev/null || true
fi

# Detectar si es una instalación nueva (sin migraciones aplicadas)
if [ "$EXTERNAL_DB" = false ]; then
  DB_EXISTS=$($PSQL -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname='$POSTGRES_DATABASE'" 2>/dev/null || echo "")
  if [ -z "$DB_EXISTS" ]; then
    echo "Database does not exist. Creating..."
    bundle exec rails db:create || { echo "ERROR: db:create failed. Aborting."; exit 1; }
  fi
fi

MIGRATIONS_COUNT=$($PSQL -tAc "SELECT COUNT(*) FROM schema_migrations" 2>/dev/null | tr -d '[:space:]' || echo "0")
FRESH_DB=false
if [ "$MIGRATIONS_COUNT" = "0" ]; then
  FRESH_DB=true
  echo "Fresh database detected."
else
  echo "Existing database ($MIGRATIONS_COUNT migrations applied). Running pending migrations only."
fi

# Correr migraciones
echo "Running migrations..."
bundle exec rails db:migrate 2>&1 | tee /tmp/migrate_output.txt
MIGRATE_EXIT=$?

# Workaround para bug de acts-as-taggable-on con Ruby 3.4
if grep -q "ActsAsTaggableOn::Taggable::Cache" /tmp/migrate_output.txt; then
  echo "Applying workaround for migration 20231211010807..."
  $PSQL -c "ALTER TABLE conversations ADD COLUMN IF NOT EXISTS cached_label_list varchar;" 2>/dev/null || true
  $PSQL -c "INSERT INTO schema_migrations (version) VALUES ('20231211010807') ON CONFLICT DO NOTHING;" 2>/dev/null || true
  bundle exec rails db:migrate 2>&1 | tee /tmp/migrate_output.txt
  MIGRATE_EXIT=$?
fi

if [ $MIGRATE_EXIT -ne 0 ]; then
  echo "ERROR: Migrations failed. Check logs above. Aborting startup."
  exit 1
fi

# Seeds: en DB nueva O si installation_configs está vacío
IC_COUNT=$($PSQL -tAc "SELECT COUNT(*) FROM installation_configs" 2>/dev/null | tr -d '[:space:]' || echo "0")
if [ "$FRESH_DB" = true ] || [ "$IC_COUNT" = "0" ]; then
  echo "Running seeds..."
  bundle exec rails db:seed || { echo "ERROR: Seeds failed. Aborting."; exit 1; }
  echo "Seeds complete."
fi

echo "Database setup complete. Starting server..."
exec "$@"
