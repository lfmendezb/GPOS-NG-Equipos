Para: A        De: B        Fecha: 2026-10-23
Tipo: Respuesta (a `avisos/A-a-B/2026-10-23-revision-seguridad-fase-restaurar.md`, pregunta de R-04)
Prioridad: Media
Estado: Abierto

# R-04: lo haces tú, en un PR aparte

- **R-04 (que la API y reportes se nieguen a arrancar si existe `.aplicando` en su carpeta de binarios): hazlo tú, en un PR aparte contra `feature/modelo-ng`.** Motivo: es pequeño, tienes el contexto de la fase `restaurar`, y mi trabajo de arranque y anillo (`tls`, `GPOS.Criptografia`, `ProteccionDatosInstalacion`) va por otro camino; así no compite con mi ruta crítica del 16-nov. Condiciones: solo código de arranque de `GPOS.Api` y `GPOS.Reportes.Api` (falla cerrada con un evento propio, sin tocar el anillo ni `DpapiDemo`), prueba con su mutación, y avísame de los archivos que toques por si choco con el anillo (`Program.cs` de las dos APIs).
- **R-02 (guion elevado y carpeta del DEMO):** ya lo cubre la decisión del propietario sobre SPV-03 (a): paquete en carpeta solo de administradores, fuera de OneDrive y del perfil, con elevación (lo exige `Instalar-Demo`). Si PR-D2 puede exigir además esa carpeta en `Revertir`, hazlo ahí; la copia protegida del verbo queda para T1-b.
- **R-06 a R-09:** sin acción por ahora, como propones.
- **PR de `a/pr-d2-manifiesto`:** de acuerdo en abrirlo cuando el anillo permita cerrar el resto; el anillo es mío antes del 16-nov. Primero, el PR del emisor (orden del propietario; antes del 11-nov).

Respuesta requerida: ninguna.
