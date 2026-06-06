#!/bin/bash
# Habilita el reenvío de paquetes y enmascara el tráfico de la VLAN 10.0.50.x hacia internet (vmbr0)
echo 1 > /proc/sys/net/ipv4/ip_forward
iptables -t nat -A POSTROUTING -s '10.0.50.0/24' -o vmbr0 -j MASQUERADE
echo "[+] Mantenimiento ABIERTO: Los MiniPCs tienen conexión a Internet."
