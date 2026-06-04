#!/bin/sh
set -e

rm -rf /app/tmp/pids/server.pid
rm -rf '/app/tmp/cache/*'

# Esperar a Postgres
PG_READY="pg_isready -h $POSTGRES_HOST -p 5432 -U $POSTGRES_USERNAME"
echo "Waiting for postgres..."
until $PG_READY; do
  sleep 2
done
echo "Postgres ready."

bundle install

# Detectar si la DB existe y tiene migraciones aplicadas
DB_EXISTS=$(PGPASSWORD=$POSTGRES_PASSWORD psql -h $POSTGRES_HOST -U $POSTGRES_USERNAME -d postgres \
  -tAc "SELECT 1 FROM pg_database WHERE datname='$POSTGRES_DATABASE'" 2>/dev/null || echo "")

FRESH_DB=false
if [ -z "$DB_EXISTS" ]; then
  echo "Database does not exist. Creating..."
  bundle exec rails db:create
  FRESH_DB=true
  # Crear el schema si se especificó uno distinto a public
  SCHEMA=${POSTGRES_SCHEMA:-public}
  if [ "$SCHEMA" != "public" ]; then
    echo "Creating schema '$SCHEMA'..."
    PGPASSWORD=$POSTGRES_PASSWORD psql -h $POSTGRES_HOST -U $POSTGRES_USERNAME -d $POSTGRES_DATABASE \
      -c "CREATE SCHEMA IF NOT EXISTS $SCHEMA;" 2>/dev/null || true
  fi
else
  echo "Database exists. Checking migrations..."
fi

# Correr migraciones pendientes
echo "Running migrations..."
bundle exec rails db:migrate 2>&1 | tee /tmp/migrate_output.txt || true

# Workaround para bug de acts-as-taggable-on con Ruby 3.4
if grep -q "ActsAsTaggableOn::Taggable::Cache" /tmp/migrate_output.txt; then
  echo "Applying workaround for migration 20231211010807..."
  PGPASSWORD=$POSTGRES_PASSWORD psql -h $POSTGRES_HOST -U $POSTGRES_USERNAME -d $POSTGRES_DATABASE \
    -c "ALTER TABLE conversations ADD COLUMN IF NOT EXISTS cached_label_list varchar;" 2>/dev/null || true
  PGPASSWORD=$POSTGRES_PASSWORD psql -h $POSTGRES_HOST -U $POSTGRES_USERNAME -d $POSTGRES_DATABASE \
    -c "INSERT INTO schema_migrations (version) VALUES ('20231211010807') ON CONFLICT DO NOTHING;" 2>/dev/null || true
  bundle exec rails db:migrate
fi

# Seeds solo en base de datos nueva
if [ "$FRESH_DB" = true ]; then
  echo "Running seeds..."
  bundle exec rails db:seed
  echo "Seeds complete."
fi

echo "Database setup complete. Starting server..."
exec "$@"
