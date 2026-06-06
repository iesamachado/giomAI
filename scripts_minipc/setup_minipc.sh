#!/bin/bash

echo "1. Instalando Ollama..."
curl -fsSL https://ollama.com/install.sh | sh

echo "2. Configurando Ollama para escuchar en la red local..."
sudo mkdir -p /etc/systemd/system/ollama.service.d
# Corrección del error: usar sudo tee o bash -c para que la redirección funcione con permisos de superusuario
cat <<EOF | sudo tee /etc/systemd/system/ollama.service.d/override.conf > /dev/null
[Service]
Environment="OLLAMA_HOST=0.0.0.0:11434"
EOF

echo "3. Reiniciando el servicio..."
sudo systemctl daemon-reload
sudo systemctl restart ollama

echo "4. Descargando modelo base (Ejemplo: Llama 3.2 de 3B)..."
ollama pull llama3.2

echo "Instalación completada. Este nodo está listo para recibir peticiones."
