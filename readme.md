## COMANDOS

# Clonar el repo
git clone https://github.com/buttiepedro/chat.git

# Entrar al proyecto
cd chat

# Buildar la imagen usando el Dockerfile de la raiz
sudo docker build -t chat-app .

# Levantar el contenedor y dejarlo persistente
sudo docker run -d \
  --restart unless-stopped \
  --name chat-app \
  -p 3000:3000 \
  chat-app


# LUEGO DE INSTALAR
#### INSTALLATION_NAME = Bit Chat

- docker exec -it TU_CONTAINER sh
- bundle exec rails c
- InstallationConfig.find_by(name: 'INSTALLATION_NAME').update(value: 'BIT Chat')
