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
| `ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY` | Generá con `bundle exec rails db:encryption:init` |
| `ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY` | Idem |
| `ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT` | Idem |
| `FRONTEND_URL` | URL pública de la app (ej: `https://chat.tudominio.com`) |
| `REDIS_URL` | URL de Redis (ej: `redis://ip:6379`) |

**Conexión a Postgres — elegir una opción:**

**Opción A** — Connection string (Neon, Supabase, Railway, etc.):
```
DATABASE_URL=postgresql://user:password@host/database?sslmode=require
```

**Opción B** — Parámetros individuales (Postgres propio o Docker):
```
POSTGRES_HOST=
POSTGRES_DATABASE=
POSTGRES_USERNAME=
POSTGRES_PASSWORD=
```

Opcionalmente, para usar un schema distinto a `public`:
```
POSTGRES_SCHEMA=bitchat
```

#### 3. Levantar

```bash
docker compose up -d --build
```

El entrypoint se encarga automáticamente de:

- **Base de datos nueva**: la crea, corre todas las migraciones y carga los seeds
- **Base de datos existente**: corre solo las migraciones pendientes
- En ambos casos arranca el servidor cuando todo está listo

#### 4. Verificar que está corriendo

```bash
docker compose logs -f web
```

Cuando veas `Database setup complete. Starting server...` seguido de `Listening on http://0.0.0.0:3000`, la app está lista.

La app queda disponible en `http://localhost:3000`.

---

## Post-instalación

Cambiar el nombre de la instalación a **BIT Chat** (solo la primera vez):

```bash
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

## Actualizaciones

Para actualizar a una nueva versión basta con rebuildar:

```bash
docker compose up -d --build
```

El entrypoint detecta que la base ya existe y solo corre las migraciones nuevas. No toca los datos.

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

# Resetear todo (borra la base de datos)
DISABLE_DATABASE_ENVIRONMENT_CHECK=1 bundle exec rails db:drop
docker compose down
docker compose up -d --build
```
