#!/bin/bash

# Script para añadir o quitar nodos del clúster dinámicamente

if [ "$#" -ne 2 ]; then
    echo "Uso: $0 [add|remove] <IP_DEL_NODO>"
    echo "Ejemplo: $0 add 10.0.50.13"
    exit 1
fi

ACTION=$1
IP=$2
NGINX_CONF="nginx.conf"

if [ ! -f "$NGINX_CONF" ]; then
    echo "Error: No se encuentra el archivo $NGINX_CONF en el directorio actual."
    echo "Asegúrate de ejecutar este script desde la carpeta donde está nginx.conf."
    exit 1
fi

case "$ACTION" in
    add)
        if grep -q "server $IP:11434;" "$NGINX_CONF"; then
            echo "El nodo $IP ya está en el clúster."
        else
            # Inserta la IP justo antes del comentario de añadir más nodos
            sed -i "/# Añade los demás aquí.../i \\        server $IP:11434;" "$NGINX_CONF"
            echo "✅ Nodo $IP añadido a la configuración."
        fi
        ;;
    remove)
        if ! grep -q "server $IP:11434;" "$NGINX_CONF"; then
            echo "El nodo $IP no está en el clúster."
        else
            # Elimina la línea que contiene la IP
            sed -i "/server $IP:11434;/d" "$NGINX_CONF"
            echo "❌ Nodo $IP eliminado de la configuración."
        fi
        ;;
    *)
        echo "Acción no válida. Usa 'add' o 'remove'."
        exit 1
        ;;
esac

# Recargar Nginx si el contenedor está en ejecución
if docker ps --format '{{.Names}}' | grep -q "^ai-load-balancer$"; then
    echo "Recargando el balanceador de carga Nginx en caliente..."
    docker exec ai-load-balancer nginx -s reload
    echo "Nginx recargado con éxito."
else
    echo "⚠️ Aviso: El contenedor 'ai-load-balancer' no está en ejecución. Los cambios se aplicarán automáticamente cuando lo inicies con docker-compose."
fi
