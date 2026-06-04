FROM chatwoot/chatwoot:v4.11.0

# Copiar solo assets custom sin romper vite
COPY public /app/public

# Soporte para POSTGRES_SCHEMA
COPY config/database.yml /app/config/database.yml

# Entrypoint con setup automático de DB
COPY docker/entrypoints/rails.sh /app/docker/entrypoints/rails.sh
RUN chmod +x /app/docker/entrypoints/rails.sh