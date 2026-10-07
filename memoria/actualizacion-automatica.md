---
name: actualizacion-automatica
description: "Diseño acordado con el propietario (2026-10-05) para actualizar GPOS NG sin versiones visibles y con publicación continua: agente automático, Google Drive como origen, manifiesto firmado"
metadata:
  node_type: memory
  type: project
  originSessionId: 1cee00aa-ab02-439f-846e-6899ce03c1d6
  modified: 2026-10-05T13:50:11.923Z
---

El 2026-10-05 el propietario pidió que, tras la primera versión candidata («GPOS ARGON»), las actualizaciones sean **sin versiones visibles para el cliente y con publicación continua (rolling release)**, porque «la actualización manual es un dolor de cabeza». Aceptó todas las observaciones de la sesión:

- **Agente de actualización automático** (servicio de Windows, patrón de la herramienta de respaldos) en la central y en cada nodo: descarga, verifica, aplica en ventana de mantenimiento (después del Z o de noche), respalda antes, migra con `GPOS.Migracion`, verifica y **revierte solo** si falla. La Web se actualiza con la instalación; MAUI necesita su actualizador.
- **Anillos** Desarrollo, Beta, Demostración y Producción (ver [[clasificacion-empresas-pendiente]]); vía rápida para cambios fiscales de la DGII. **Funciones activables por empresa.**
- **Regla de los dos tiempos en el esquema** (expandir y luego contraer): imprescindible para que central y nodos convivan en versiones N y N−1 y para poder revertir. Recomendado firmarla como ADR ya.
- **Origen: carpeta de Google Drive de su Workspace**, una carpeta por anillo, con paquetes por componente (API, Web, App) y un **archivo de versión firmado digitalmente** (versión por componente, versión mínima, anillo, hash y tamaño, notas). Acceso de los agentes con **cuenta de servicio de solo lectura**, nunca enlace público. Cifrado del paquete opcional (no sustituye la firma). En clientes con nodos, la central descarga y reparte. Origen intercambiable (mañana otro almacenamiento).
- **Firmas:** el certificado del e-CF **no** se usa para esto (es su firma legal ante la DGII, sin uso de firma de código). Programas e instaladores: certificado de **firma de código** según ADR-33 (faltan el nombre legal de la empresa y el custodio suplente). Archivo de versión: **par de llaves propio**, privada protegida en su equipo de publicación, pública dentro del agente, con plan de rotación.

**How to apply:** versión mínima del agente adelantada como pista paralela (propuesta formal pendiente de pedir al arquitecto-maestro y a DevOps cuando el propietario lo confirme); anillos completos y funciones activables antes del primer cliente en producción.

Relacionado: [[decision-modelo-datos-propio-pendiente]], [[todo-es-desarrollo]].
