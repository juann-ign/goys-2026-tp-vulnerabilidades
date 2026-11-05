# Entregable — TP PHP2Shell / Node2Shell

**Grupo:** _completar_ · **Fork del grupo:** _completar_ · **Rama:** `grupo-05`
**Fecha:** jueves 29/10/2026

| Integrante | Usuario de GitHub | Rol en el TP |
|---|---|---|
| Juan Ignacio Atencio | juann-ign | Inventario, priorización, mitigación, parcheo y contención |
| Ian Vidmar | | Detección y caza de amenazas |
| Patricio Borda | | Comunicación de crisis e informe ejecutivo |

> Roles sugeridos: inventario, cambios/parche, detección, contención/comunicación.
> Todos tienen que poder explicar su parte y una parte ajena.

---

## 1. Inventario

**Estado inicial verificado:** el script `./scripts/arrancar-2h.sh` inició los tres contenedores y `docker compose ps -a` los mostró en estado `healthy`. Se ejecutó `./scripts/inventario.sh` antes de aplicar mitigaciones o parches.

| Activo | Versión | ¿Expuesto a Internet? | ¿Procesa contenido no confiable? | ¿Afectado? | Evidencia |
|--------|---------|:---------------------:|:--------------------------------:|:----------:|-----------|
| Portal PHP | PHP **8.3.35** (CLI, NTS); `session.upload_progress.enabled=1` | **No**, en el laboratorio aislado; producción no verificada | _Por confirmar según flujo de la aplicación_ | **Sí, versión inicial del escenario vulnerable** | `inventario.sh`: versión PHP y `session.upload_progress.enabled=1` |
| API Node.js | Node.js **v22.23.3**, Brotli integrado **1.1.0**; sin paquete externo | **No**, en el laboratorio aislado; producción no verificada | _Por confirmar según endpoints_ | **Sí, versión inicial del escenario vulnerable** | `inventario.sh`: versión Node/Brotli y ausencia de dependencia externa |
| Servicio Python | Python **3.11.18**, paquete `brotli` **1.0.9** | **No**, en el laboratorio aislado; producción no verificada | _Por confirmar según aplicación_ | **Sí, versión inicial del escenario vulnerable** | `inventario.sh`: versión Python y paquete Brotli |

**Salida original del inventario (estado previo al parche):**

```console
$ ./scripts/inventario.sh
== PHP ==
PHP 8.3.35 (cli) (built: Oct 21 2026 00:33:53) (NTS)
session.upload_progress.enabled=1

== Node.js ==
v22.23.3 / brotli 1.1.0
-- dependencias con brotli:
   (sin paquete brotli externo: lo aporta el runtime)

== Python ==
python 3.11.18
brotli 1.0.9
```

**Comprobación de estado de los contenedores:**

```text
node-lab   Up (healthy)   3000/tcp
php-lab    Up (healthy)   80/tcp
py-lab     Up (healthy)   8000/tcp
```

**Supuestos de exposición:** El entorno del TP emplea una red interna de Docker y las salidas de `docker compose ps` muestran puertos de contenedor (`80/tcp`, `3000/tcp`, `8000/tcp`), sin publicación de puertos al host en esa salida. Por eso no se considera que los servicios del laboratorio estén expuestos a Internet. No hay evidencia aportada sobre un proxy externo o un despliegue productivo, por lo que no se infiere su exposición real. La recepción de contenido no confiable debe corroborarse revisando endpoints y escenarios de entrada.

---

## 2. Priorización y decisión

| Activo | CVSS | Explotación real | Exposición | Criticidad | Decisión y plazo |
|--------|:----:|:----------------:|:----------:|:----------:|------------------|
| | | | | | |
| | | | | | |
| | | | | | |

**Justificación:** _¿por qué ese orden? ¿qué evidencia nueva cambiaría la decisión?_

---

## 3. Mitigación, parche y reversión

| Fecha/hora | Activo | Cambio | Antes | Después | Reversión |
|------------|--------|--------|-------|---------|-----------|
| | | | | | |
| | | | | | |

**Prueba funcional mínima:** _¿qué verificaron para saber que la app sigue viva?_

**Qué no se pudo probar:** _declararlo explícitamente._

---

## 4. Detección y caza

**Hipótesis:** _una frase: proceso, padre, horario, evidencia esperada._

**Hallazgos en `audit.log`:**

| Línea / timestamp | Host | Padre → hijo | ¿Anómalo? | Por qué |
|-------------------|------|--------------|:---------:|---------|
| | | | | |
| | | | | |

**¿Hay compromiso?** _sí/no/indeterminado, con evidencia._

**Regla propuesta para Node.js:** _qué proceso observa, qué condición y qué falso
negativo podría tener._

**Limitaciones del log:** _usuario, IP de origen, retención, ruido, etc._

---

## 5. Contención

| Control | Configuración | Evidencia | ¿Funciona? |
|---------|---------------|-----------|:----------:|
| Red sin salida | `internal: true` | Los tres servicios devuelven SIN SALIDA | Sí, en la prueba |
| Usuario sin privilegios | | | |
| Filesystem read-only | | | |
| Capabilities mínimas | | | |
| Límites de memoria/PIDs | | | |
| Rechazo de Brotli innecesario | | | |

**Prueba de salida a Internet:** Se ejecutó ./scripts/verificar-contencion.sh sobre los tres servicios del laboratorio. PHP devolvió SIN SALIDA, Node.js devolvió SIN SALIDA TypeError y Python devolvió SIN SALIDA URLError. Los resultados son consistentes con la imposibilidad de establecer conexiones externas desde la red Docker aislada, configurada con internal: true.

La salida del script fue conservada en entregables/grupo-05/capturas/contencion-inicial.txt. Los demás controles declarados en Docker Compose requieren verificaciones adicionales para confirmar su aplicación efectiva.

---

## 6. Conclusión (5 líneas)

_¿Qué harían distinto en las primeras 2 horas?_

---

## 7. Checklist antes de entregar

- [X] El laboratorio arrancó y los 3 servicios quedaron `healthy`.
- [Z] Inventario con evidencia (versión, SAPI, configuración).
- [ ] Matriz con decisión y plazo.
- [ ] Parche aplicado y verificado; reversión documentada.
- [ ] Al menos 3 controles de contención probados.
- [ ] `deteccion.md` completo.
- [ ] `informe.md` individual completo.
- [ ] Sin claves, tokens ni placeholders.
- [ ] Repo pusheado y PR abierto.

Checklist completa: [`../docs/checklist-entrega.md`](../docs/checklist-entrega.md).
