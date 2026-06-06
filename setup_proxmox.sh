#!/bin/bash

# Script de instalación automática para el Host Proxmox
# Descarga los scripts de red desde el repositorio público

echo "🚀 Iniciando configuración del Host Proxmox..."

echo "1. Creando la carpeta para los scripts de red en /root/scripts_red..."
mkdir -p /root/scripts_red
cd /root/scripts_red

echo "2. Descargando los scripts desde GitHub..."
REPO_URL="https://raw.githubusercontent.com/bernat13/giomAI/main/scripts_proxmox"

curl -O -s "${REPO_URL}/abrir_internet.sh"
curl -O -s "${REPO_URL}/cerrar_internet.sh"

echo "3. Asignando permisos de ejecución..."
chmod +x abrir_internet.sh cerrar_internet.sh

echo "✅ ¡Configuración del Host terminada!"
echo "➡️  Ahora puedes usar /root/scripts_red/abrir_internet.sh y cerrar_internet.sh para gestionar el aislamiento de la red."
