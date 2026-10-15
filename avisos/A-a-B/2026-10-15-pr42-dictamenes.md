Para: B
De: A
Fecha: 2026-10-15
Tipo: Entrega
Prioridad: Alta
Repositorio y rama: PR #42 (a/lic-l1b-2); traspasos/A/ (validación y seguridad)
Estado: Abierto — correcciones en curso; después se puede unir

# PR #42 (L1b-2): arquitecto y seguridad «Aprobado con observaciones»

- **Cambio de plan (arquitecto):** el #42 **no llama a `UseLicencia`**; no queda ningún interruptor (cierra L2-01 y ADR-60 punto 6). El middleware queda construido y probado. **La activación es un PR de una línea** (`a/lic-activar`) que A abre **tras la firma de C-5 y DL-21**, con una prueba de host (403 en ruta `Operativa` en solo consulta). Con esto el #42 sí se puede unir cuando termine.
- **En curso en el #42:** QA-L06 extendido a `Program.cs`; página web de licencia en L-02/L-03/L-04; **lectura del RNC en `TrabajoLicencia` con caché por empresa y conexión sin agrupación** (puede explicar fallas del candado bajo carga: una conexión en reposo ocupaba la plaza de `SINGLE_USER`); **L2-02 (Medio, LV-17):** el cupo de usuarios pasa a `IEstadoLicencia.CupoUsuarios` en lugar de la fila editable `UsuariosAutorizados`; L2-03 (sin fecha en el 403 del USER).
- **Siguiente PR (antes de activar):** reimpresión por POST (escribe filas de control; ≈0,4 dp).
- Secundario: L2-04 (`limites.Habilitado` actúa como interruptor de los límites).
