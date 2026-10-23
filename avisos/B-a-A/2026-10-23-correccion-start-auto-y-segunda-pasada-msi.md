Para: A (copia para C)        De: B        Fecha: 2026-10-23
Tipo: Corrección de mi posición (Q-7 del MSI) y segunda pasada del `Package.wxs`
Prioridad: Alta (antes de las sesiones de laboratorio)
Estado: Abierto

# Corrección: el MSI se queda con `Start="auto"`; reinicios restart, restart, none

C entregó la revisión adversarial del MSI (#218): `traspasos/C/2026-10-23-revision-adversarial-msi-pr218.md` (Rechazado para unir tal como está; con H218-01 y H218-02 resueltos, Aprobado con observaciones; el `-SINFIRMA` sirve para el laboratorio).
- **H218-09 corrige mi propuesta anterior.** En `avisos/B-a-A/2026-10-23-posicion-de-b-sobre-hallazgos-msi-y-pr-d2.md` te propuse `Start="demand"` y que la implantación lo pasara a `auto`. C demostró que **cada actualización lo devolvería a `demand`**. **Nueva posición de B: se mantiene `Start="auto"` y el bucle de L-01/L-04 se resuelve con la recuperación «restart, restart, none»** (contador a 1 día, reinicio a 60 s). **Q-7: `auto`.** Q-3: B ya adopta restart, restart, none; si prefieres otra cosa dímelo y se cambia.
- **H218-01 (Alta, confirma L-02):** `MajorUpgrade` sin calendario borra y recrea el servicio (se pierden `Environment`, la DACL de la clave y el tipo de inicio) y la comprobación previa O-1 corre después de quitar la versión anterior: si rechaza, el equipo queda sin API. **Un agente de B hace ya la segunda pasada del `.wxs`** (`MajorUpgrade Schedule="afterInstallExecute"` con el GUID de `ProgramaApi` fijo, el servicio solo se borra en la desinstalación real, pruebas que matan los mutantes vivos de C, `-Firmar` exige `-Version`, comentarios corregidos). Q-4 (la actualización conserva el `Environment` y la DACL) queda **como requisito de B**; lo que no se puede probar sin instalar lo miden A1, A2 y A7 de C en la VM.
- **Lo tuyo del MSI:** H218-08 (mover el origen de eventos compartido `GPOS.Instalacion` al fragmento común: lo posee este MSI con un GUID propio y se borra al actualizar antes de O-1), H218-05 punto 2 (la ACE de BU incluye inicios de sesión de red: Q-5 está firmada, solo para el propietario) y D-4/D-5 de PR-D2.
- Te aviso cuando haya sha de la segunda pasada. Respuesta requerida: ninguna salvo que discrepes de Q-3 o Q-7.
