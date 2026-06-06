# GiomAI - Despliegue de Clúster IA en Proxmox

Este repositorio contiene todos los scripts y archivos de configuración necesarios para montar la infraestructura de IA distribuida. La arquitectura consta de un servidor Host (Proxmox), varios MiniPCs que actúan como Nodos de Cómputo (Ollama), y una Máquina Virtual que hace de "Cerebro" (Balanceador, Open-WebUI y Túnel Zrok).

## 🖥️ Características del Servidor Host

El núcleo de la infraestructura se ejecuta en un servidor **Dell PowerEdge R740xd**, un equipo de centro de datos diseñado para funcionar ininterrumpidamente y con una capacidad de virtualización excepcional.

### Especificaciones Principales (Configuración Actual)

| Componente | Detalle Técnico | Impacto en el Laboratorio (ASIR / IA) |
| :--- | :--- | :--- |
| **Modelo** | Dell PowerEdge R740xd | Chasis de 2U en rack. La "xd" (eXtreme Disk) indica que está optimizado para alta densidad de almacenamiento. |
| **Procesadores (CPU)** | 2x Intel Xeon Gold 6138 | Arquitectura Skylake. 40 núcleos físicos y 80 hilos en total. Excelente para virtualización en Proxmox, pero al carecer de instrucciones AVX-512 VNNI, sufren en inferencia pura de IA comparado con una GPU. |
| **Memoria RAM** | 128 GB DDR4 | Arquitectura NUMA (distribuida entre los dos procesadores). Capacidad masiva que permite cargar en memoria RAM modelos de lenguaje enormes (hasta 70B de parámetros). |
| **Tarjetas de Red (NIC)** | Mínimo 2 interfaces (eno1, eno2) | Típicamente traen una tarjeta hija con 4 puertos a 1GbE o combinaciones de 10GbE. Perfecto para crear redes aisladas (VLANs/Fosos) a nivel físico sin saturar el bus principal. |

### Capacidades de Expansión (R740xd)

Este equipo es una bestia diseñada para la escalabilidad. Si en el futuro necesitas ampliarlo, esto es lo que soporta el chasis de fábrica:

* **Almacenamiento Masivo:** Dependiendo del *backplane* frontal, soporta hasta 24 discos de 2.5" (SAS/SATA/NVMe) o hasta 12 discos de 3.5". Cuenta con controladora RAID por hardware (línea PERC de Dell).
* **Capacidad PCIe (Clave para IA):** Tiene múltiples ranuras PCIe Gen3 (hasta 8 ranuras dependiendo de los risers). Esto significa que puedes instalar varias tarjetas gráficas dedicadas (NVIDIA RTX o Tesla) en paralelo en el futuro.
* **Fuentes de Alimentación (PSU):** Doble fuente redundante en caliente (Hot-Plug). Suelen ser de 750W, 1100W o 1600W. Si se instalan GPUs, las fuentes de 1100W en adelante son necesarias.
* **Gestión Remota (iDRAC9):** Cuenta con un puerto de red dedicado y un chip controlador base para gestión *Out-of-Band*. Permite acceder a la BIOS, instalar sistemas operativos y monitorizar el hardware incluso si Proxmox está caído o el servidor está apagado.

---

## 🚀 Proceso de Despliegue y Scripts

He estructurado la configuración en tres carpetas según la fase de despliegue:

### Fase 1: El Servidor Host (Proxmox)
Ubicación: `/scripts_proxmox/`

Estos scripts se usan para abrir o cerrar el acceso a Internet a los MiniPCs que normalmente se encuentran en la subred aislada (ej. `10.0.50.0/24`).

*   **`abrir_internet.sh`**: Habilita el IP forwarding y enmascara el tráfico para que los MiniPCs tengan internet (necesario para instalar cosas).
*   **`cerrar_internet.sh`**: Elimina las reglas de enmascaramiento, devolviendo a los MiniPCs a su aislamiento.

**Uso:** 
1. Subir estos scripts a Proxmox (ej. en `/root/scripts_red/`).
2. Darles permisos de ejecución: `chmod +x abrir_internet.sh cerrar_internet.sh`.

### Fase 2: Nodos de Cómputo (Los MiniPCs)
Ubicación: `/scripts_minipc/`

Antes de ejecutar este script, asegúrate de haber ejecutado `abrir_internet.sh` en Proxmox.

*   **`setup_minipc.sh`**: Instala Ollama, lo configura para que escuche peticiones en la red local (0.0.0.0:11434), reinicia el servicio y descarga el modelo base (`llama3.2`).

> **💡 Corrección de Errores Aplicada:**
> En la documentación original había un error en este script: 
> `sudo cat <<EOF > /etc/systemd/system/ollama.service.d/override.conf`
> La redirección de salida (`>`) se ejecuta con los permisos del usuario normal, lo cual daría un error de "Permiso denegado". Lo he corregido usando `tee` con sudo:
> `cat <<EOF | sudo tee /etc/systemd/system/ollama.service.d/override.conf > /dev/null`

**Uso:**
Entrar a cada MiniPC y ejecutar: `bash setup_minipc.sh`. Una vez completado en todos los nodos, ejecutar `cerrar_internet.sh` en Proxmox.

### Fase 3: La Máquina Virtual ("El Cerebro")
Ubicación: `/vm_docker/`

Esta máquina se encarga de balancear la carga entre los MiniPCs, servir la interfaz y exponer el servicio de forma segura.

*   **`nginx.conf`**: Configura un proxy inverso con balanceo de carga `least_conn` que reparte las peticiones entre los MiniPCs disponibles en la subred aislada (10.0.50.11, 10.0.50.12, etc.).
*   **`docker-compose.yml`**: Levanta Nginx (balanceador), Open-WebUI (interfaz) y Zrok (túnel para acceso desde el exterior).

> **💡 Nota sobre Open-WebUI:**
> Open-WebUI apunta al balanceador Nginx mediante la variable `OPENAI_API_BASE_URLS=http://nginx-balancer:11434/v1`. Ollama soporta el endpoint compatible con OpenAI (`/v1`) desde la versión 0.1.24, por lo que esta configuración funcionará perfectamente.
> Recuerda cambiar `TU_TOKEN_DE_ZROK_AQUI` por tu token real de Zrok antes de lanzar los contenedores.

**Uso:**
1. Instalar Docker en la VM.
2. Copiar los archivos `nginx.conf` y `docker-compose.yml` a `/opt/ai-cluster/`.
3. Ejecutar `docker compose up -d`.

---

## 🔄 Mantenimiento: Añadir o Quitar Nodos (MiniPCs)

Para escalar el clúster (añadir nuevos MiniPCs) o retirar nodos en mantenimiento sin interrumpir el servicio, he creado un script de gestión que actualiza el balanceador de carga en caliente.

### 1. Preparar el nuevo MiniPC (Solo si vas a añadir)

Si vas a añadir un nodo nuevo, primero debes prepararlo usando el script de configuración que hicimos para los MiniPCs.
1. En Proxmox, ejecuta `./scripts_proxmox/abrir_internet.sh` para dar salida a internet a la red aislada.
2. En el nuevo MiniPC, ejecuta el script de configuración que dejará todo instalado y descargado:
   ```bash
   bash scripts_minipc/setup_minipc.sh
   ```
3. En Proxmox, ejecuta `./scripts_proxmox/cerrar_internet.sh` para volver a aislar la red.

### 2. Actualizar el Clúster (En la Máquina Virtual "Cerebro")

En la carpeta `/vm_docker/` de la Máquina Virtual, dispones del script `manage_nodes.sh`. Este script modifica automáticamente `nginx.conf` y recarga el balanceador sin interrumpir las peticiones actuales.

**Añadir un nodo:**
```bash
chmod +x manage_nodes.sh
./manage_nodes.sh add <IP_DEL_NUEVO_NODO>
# Ejemplo: ./manage_nodes.sh add 10.0.50.13
```

**Quitar un nodo:**
```bash
./manage_nodes.sh remove <IP_DEL_NODO>
# Ejemplo: ./manage_nodes.sh remove 10.0.50.11
```

El script se encarga de:
- Modificar la lista de balanceo de carga en `nginx.conf`.
- Comprobar si el contenedor `ai-load-balancer` está corriendo.
- Ejecutar un `nginx -s reload` dentro del contenedor para aplicar los cambios instantáneamente sin corte de servicio.

---

## 🎯 Resumen del Flujo de Trabajo

1. El alumno accede a `https://tu-enlace.share.zrok.io`.
2. Zrok redirige de forma segura la petición al contenedor `open-webui` por la red general (vmbr0).
3. Open-WebUI envía el prompt al balanceador `nginx-balancer`.
4. Nginx evalúa qué MiniPC tiene menos carga activa (red aislada vmbr1, subred 10.0.50.x) y le pasa la solicitud.
5. El MiniPC genera la respuesta de forma segura y aislada, enviándola de vuelta al alumno. Todo ello sin abrir puertos públicos en el instituto.
