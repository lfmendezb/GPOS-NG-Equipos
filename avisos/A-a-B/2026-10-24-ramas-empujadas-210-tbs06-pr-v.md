Para: B        De: A        Fecha: 2026-10-24
Tipo: Entrega (ramas empujadas, sin PR; tanda 8 puntos 1, 3 y 4, y PR-V)
Prioridad: Media
Estado: Abierto

# Ramas empujadas (ningún PR abierto: espero la orden del propietario)

| Rama | Punta | Base | Contenido |
|---|---|---|---|
| `a/t4-02a-correcciones` | `4c15743d` | `b/t4-02a` @ `9288b01a` | #210: H210-01 (`3be94dbe`), H210-02 (`8631302f`), S210-01 (`c209018b`), S210-02 (`33dc950e`), S210-06 con R2 (`c1d7b51a`), R3 (`4c15743d`) |
| `a/tbs06-r212-pruebas` | `95669cd7` | `feature/modelo-ng` @ `1b310591` | R206-01 (`25502f03`), R206-02 (`0352c443`), R212-01 (`95669cd7`, solo comentario) |
| `a/pr-v-verbos-servidor` | `df422dc9` | `feature/modelo-ng` (merge, 0 de atraso) | PR-V con T1-10 y el SDDL de Q-5 estrictos contra el `Package.wxs` (`2e55e5fd`); conflicto de `Program.cs` resuelto (unión de las banderas). Sin PR |

**Evidencia (corrida por A, no la suite completa):** #210 `ClienteRender|ContratoRenderTests` 78/78 (antes 59); TBS-06 14/14; PR-V `GPOS.Tests.Servidor` 229/229 y 917/918 en Servidor, Migración, EventId únicos y Arquitectura. La falla de PR-V, `EsquemaPendienteAccesoTests.Una_empresa_cuya_base_no_existe_…`, falla igual en `a/t4-04-emisor` (sin PR-V). Mutaciones en rojo, reportadas por el agente que hizo el trabajo: no las repetí.

## Para B (#210)
1. **H210-01 cambia el texto que verá el SUPER** (varias líneas en vez de una cortada a 300 caracteres), como pide la tabla 5.3; aún no hay llamadores (T4-02b). Si lo ves como cambio visible, que lo confirme el propietario.
2. Topes elegidos por A, documentados en el código: 4.000 caracteres (texto de formato), 1 MB (ProblemDetails) y 60 s (`ReintentarEn`). Ajústalos si quieres.
3. H210-02 está corregido en el cliente; S210-03 a S210-05 (API de reportes) quedan fuera, como indicaste.
4. Quitar `RedactLoggedHeaders` del todo no hace fallar la prueba del token; el agente supone que .NET 10 ya redacta por omisión (no verificado).

## Para B (TBS-06 y R212-01)
5. La frase de R212-01 cita «(CS-3)»; si la prefieres sin esa referencia, se quita.
6. La prueba R206-01 cuenta comandos por el evento `WriteCommandBefore` de SqlClient (reflexión): si cambia, pasa a rojo, no a falso verde.

## Aclaración a mi aviso del 23-oct (acuse tanda 8)
Dije que la corrección de D-4 (P-D2-01) era una propuesta: ya está hecha y empujada en `a/pr-d2-manifiesto` (`812d1790`, cada copia previa lleva su identificador).

## Falta
Abrir los PR (el del #210 contra `b/t4-02a`, y el de PR-V antes del 3-nov) cuando el propietario lo ordene. Sigo con el tablero (R205-01 a R205-04), S217-02 y R-04/R-09/P-D2-04.

Respuesta requerida: ninguna.
