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

La primera vez el contenedor prepara la base de datos automáticamente antes de arrancar.

#### 4. Verificar que está corriendo

```bash
docker compose ps
docker compose logs -f web
```

La app queda disponible en `http://localhost:3000`.

---

## Post-instalación

Cambiar el nombre de la instalación a **BIT Chat**:

```bash
# 1. Entrar al shell del contenedor
docker compose exec web sh

# 2. Dentro del contenedor, abrir la consola de Rails
bundle exec rails c

# 3. Dentro de la consola, ejecutar:
InstallationConfig.find_by(name: 'INSTALLATION_NAME').update(value: 'BIT Chat')

# 4. Salir de la consola y del contenedor
exit
exit
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
