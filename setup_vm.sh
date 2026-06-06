#!/bin/bash

# Script de instalación automática para la Máquina Virtual (Cerebro)
# Instala Docker y descarga las configuraciones desde el repositorio público

echo "🚀 Iniciando configuración de la Máquina Virtual (Cerebro)..."

echo "1. Instalando Docker y dependencias necesarias..."
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
rm get-docker.sh

echo "2. Creando el directorio /opt/ai-cluster..."
sudo mkdir -p /opt/ai-cluster
cd /opt/ai-cluster

echo "3. Descargando configuraciones desde GitHub..."
REPO_URL="https://raw.githubusercontent.com/iesamachado/giomAI/main/vm_docker"

sudo curl -O -s "${REPO_URL}/nginx.conf"
sudo curl -O -s "${REPO_URL}/docker-compose.yml"
sudo curl -O -s "${REPO_URL}/manage_nodes.sh"

echo "4. Asignando permisos de ejecución al script de gestión..."
sudo chmod +x manage_nodes.sh

echo "✅ ¡Configuración terminada!"
echo ""
echo "⚠️  PASO MANUAL REQUERIDO:"
echo "1. Ve al directorio: cd /opt/ai-cluster"
echo "2. Edita el archivo docker-compose.yml (ej: nano docker-compose.yml)"
echo "3. Cambia TU_TOKEN_DE_ZROK_AQUI por tu token real de Zrok."
echo "4. Levanta el servicio ejecutando: docker compose up -d"
