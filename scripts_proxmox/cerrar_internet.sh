#!/bin/bash
# Elimina la regla de enmascaramiento, aislando de nuevo a los MiniPCs
iptables -t nat -D POSTROUTING -s '10.0.50.0/24' -o vmbr0 -j MASQUERADE
echo "[-] Mantenimiento CERRADO: Los MiniPCs vuelven a estar aislados en foso."
