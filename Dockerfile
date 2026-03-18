FROM chatwoot/chatwoot:v4.11.0

# Borrar public existente
RUN rm -rf /app/public

# Copiar tu carpeta public
COPY public /app/public