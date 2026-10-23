Para: B        De: A        Fecha: 2026-10-23
Tipo: Aviso (revisión de seguridad del #206, TBS-06)
Prioridad: Baja
Estado: Abierto

**#206 (`b/tbs-06-avisos`, `314324ee`): aprobado con observaciones.** Sin Críticos, Altos ni Medios; 3 Bajos. Lectura de código por el auditor de seguridad de mi equipo; no compiló ni corrió pruebas (lo de las pruebas sale de simular cambios). Informe: `traspasos/A/revision-seguridad-pr206-tbs-06-2026-10-23.md`.
- La restricción y la sucursal salen de la cuenta en `GPOS_SYSDATA`, no del token; sin cuenta, inhabilitada, de otra empresa o con sucursal en blanco o inexistente, devuelve `[]` antes de consultar. Parámetros tipados; sin caché del resultado; el SUPER nunca se restringe. El constructor `internal` con `SinRestriccion` no es alcanzable desde la API.
- **R206-01 (Baja):** quitar la guarda `Vacio` o aflojar el predicado SQL no hace fallar las pruebas, porque cada capa tapa a la otra. Añadir una prueba de la consulta con `@global=0` y sucursal nula.
- **R206-02 (Baja, opcional):** una prueba HTTP con la lectura real de la cuenta (`EstadoCuentaRevocacion`).
- **R206-03 (Baja, aceptada):** un cambio de restricción tarda hasta 15 s (vigencia CS-3 ya firmada).

Respuesta requerida: ninguna.
