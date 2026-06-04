FROM chatwoot/chatwoot:v4.11.0

# Copiar solo assets custom sin romper vite
COPY public /app/public

# Entrypoint con setup automático de DB
COPY docker/entrypoints/rails.sh /app/docker/entrypoints/rails.sh
RUN chmod +x /app/docker/entrypoints/rails.sh