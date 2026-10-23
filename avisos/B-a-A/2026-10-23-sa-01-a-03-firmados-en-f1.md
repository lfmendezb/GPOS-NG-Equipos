Para: A (copia para C)        De: B        Fecha: 2026-10-23
Tipo: Decisión del propietario (SA-01, SA-02, SA-03 y el aviso de SA-06 dentro de F1)
Prioridad: Alta (F1 empieza de verdad el 26-oct)
Estado: Abierto

# SA-01, SA-02 y SA-03 firmados dentro de F1 (revisión adversarial de C del blueprint del anillo)

El propietario firmó el 2026-10-23 (hoja `docs/decisiones/2026-10-23-hoja-firma-tls-y-anillo-del-servicio.md`, PR #221; adenda en la sección 12 del blueprint, PR #219): C recomendaba «Rechazado mientras SA-01 y SA-02 no entren en F1»; con esto pasa a Aprobado con observaciones.
- **SA-01:** `--huella-recuperacion` obligatoria en `anillo --preparar` y `--anclar` (SHA-256 del `.cer`, dictada por un segundo canal: criterio de ADR-63); el `.cer` se lee una sola vez. Cambia lo que hace el técnico.
- **SA-02:** un `.cer` de recuperación vencido es solo aviso; el par de P-2 se genera con vigencia de 30 años, 3072 bits y AES-256 al exportar el PFX.
- **SA-03:** la API no arranca si en `Api\anillo` hay llaves envueltas o existe la fila del ancla y falta `GPOS.Api.anillo.json`; `--preparar` regenera el archivo con el principal existente en vez de crear un segundo principal.
- **SA-06 (solo el aviso):** el aviso de 180 días lo dan `anillo --comprobar` y `comprobar-servidor`, de forma automatizable.
- F1 pasa de 2,75 a ~3,35 dp; el agente de B los construye como commits separados en `b/f1-anillo`.
- **Para ti, A:** tu revisión de seguridad de F1 debe verificar esos tres comportamientos. Y de la revisión de C te tocan SA-07 (la CA TLS se pierde al restaurar un sitio), SA-10 (variables de entorno del usuario leídas por `GPOS.Migracion` elevado) y SA-14 (el mensaje del registro en una restauración). SA-04, SA-05, SA-08, SA-09 y SA-11 a SA-13 no están firmados (F4, devops o propietario).
- La huella obligatoria de SA-01 obliga a PR-D2: tu paso del anillo debe pasar `--huella-recuperacion` desde la instalación; cuenta con ello al escribirlo (5 al 9-nov).

Respuesta requerida: ninguna.
