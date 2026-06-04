## Deploy

#### 1. Clonar el repo y entrar al directorio

```bash
git clone https://github.com/buttiepedro/chat.git
cd chat
```

#### 2. Crear el archivo de entorno

```bash
cp .env.example .env
```

Editar `.env` y completar los valores obligatorios:

| Variable | Descripción |
|---|---|
| `SECRET_KEY_BASE` | Generá con `openssl rand -hex 64` |
| `FRONTEND_URL` | URL pública de la app (ej: `https://chat.tudominio.com`) |
| `POSTGRES_HOST` | IP o hostname del servidor Postgres |
| `POSTGRES_DATABASE` | Nombre de la base de datos |
| `POSTGRES_USERNAME` | Usuario de Postgres |
| `POSTGRES_PASSWORD` | Password de Postgres |
| `REDIS_URL` | URL de Redis (ej: `redis://ip:6379`) |

#### 3. Levantar

```bash
docker compose up -d --build
```

#### 4. Verificar que está corriendo

```bash
docker compose ps
docker compose logs -f web
```

Cuando veas `Listening on http://0.0.0.0:3000` en los logs, el servidor está listo.

#### 5. Preparar la base de datos

El contenedor **no corre las migraciones automáticamente**. Hay que hacerlo a mano la primera vez:

```bash
docker compose exec web sh
```

Dentro del contenedor:

```bash
# Correr migraciones
bundle exec rails db:migrate

# Si db:migrate falla en la migración 20231211010807 (ActsAsTaggableOn::Taggable::Cache),
# aplicarla manualmente y continuar:
PGPASSWORD=$POSTGRES_PASSWORD psql -h $POSTGRES_HOST -U $POSTGRES_USERNAME -d $POSTGRES_DATABASE \
  -c "ALTER TABLE conversations ADD COLUMN IF NOT EXISTS cached_label_list varchar;"
PGPASSWORD=$POSTGRES_PASSWORD psql -h $POSTGRES_HOST -U $POSTGRES_USERNAME -d $POSTGRES_DATABASE \
  -c "INSERT INTO schema_migrations (version) VALUES ('20231211010807') ON CONFLICT DO NOTHING;"
bundle exec rails db:migrate

# Cargar datos iniciales
bundle exec rails db:seed
```

La app queda disponible en `http://localhost:3000`.

---

## Post-instalación

Cambiar el nombre de la instalación a **BIT Chat**:

```bash
# Entrar al shell del contenedor (si no estás ya adentro)
docker compose exec web sh

# Dentro del contenedor:
bundle exec rails runner "InstallationConfig.find_by(name: 'INSTALLATION_NAME').update!(value: 'BIT Chat')"
```

Verificar que el cambio se aplicó:

```bash
bundle exec rails runner "puts InstallationConfig.find_by(name: 'INSTALLATION_NAME').value"
# => BIT Chat
```

---

## Comandos útiles

```bash
# Ver logs en tiempo real
docker compose logs -f

# Reiniciar servicios
docker compose restart

# Parar todo
docker compose down

# Rebuildar y reiniciar
docker compose up -d --build
```
