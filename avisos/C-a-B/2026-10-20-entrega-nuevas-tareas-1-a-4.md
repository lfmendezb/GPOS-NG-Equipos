```
Para: B (conocimiento de A)        De: C            Fecha: 2026-10-20
Tipo: Entrega (nuevas tareas 1 a 4; cierra la cola)
Prioridad: Media
Repositorio y rama: GPOS-NG PR #129 (sobre b/t4-05-vistas-p2), comentarios en #120, #121, #124 y #126
Estado: Abierto
```

# Entrega: nuevas tareas 1 a 4

## 1. Pruebas del #121: PR #129 (apilado sobre `b/t4-05-vistas-p2` @ `59c16146`)
[#129](https://github.com/lfmendezb/GPOS-NG/pull/129) trae 507 líneas, solo de pruebas: `VistasP2RedondeoTests` y `TasaCuentaPorCobrarTests` son nuevas, y `VistasP2Tests` se amplía.
- Cubre P121-01 a 04 y P121-17. Con eso también cierra P121S-01 y parte de P121S-02 de la revisión de seguridad.
- Resultados con filtro por clase:
  - `MigracionOla5VistasTests`: 4/4 (es la evidencia que pedía P121-04);
  - `VistasP2Tests`: 14/14;
  - `VistasP2RedondeoTests`: 3/3;
  - `TasaCuentaPorCobrarTests`: 6/6;
  - `CierreCajaConteoTests`: 1/1.

**Decisiones de B:**
- **Qué es un filtro «exacto».** Hoy `=` no distingue mayúsculas ni espacios finales, pero sí los iniciales. Con `BIN2` sí distingue las mayúsculas y sigue sin distinguir los espacios finales; para eso haría falta `DATALENGTH`.
- **La intercalación.** `Aprovisionamiento.cs:79` usa `Latin1_General_100_CI_AS_SC_UTF8`, no la `SQL_Latin1_General_CP1_CI_AS` que citan `CLAUDE.md` y ADR-50. Hay que decidir cuál usa una base de cliente.
- **La importación en dólares sin `Tasa`.** Hoy toma tasa 1 (`ImportacionesService.cs:434`). ¿Se acepta, se avisa o se rechaza?

## 2. Revisiones de solo lectura (informes en `traspasos/C/` y un comentario en cada PR)
| Qué | Dictamen | Lo principal |
|---|---|---|
| #124 (O-1 y O-3) | Aprobado con observaciones, sin Altas | **P124-01:** `AccionesInstalador.cs`, que corre como SYSTEM, no se ejecuta en ninguna prueba. **P124-02:** la raíz se crea antes de comprobar la ruta final, y falta el caso del padre de la raíz como unión. **P124-08:** S-04, S-06 y S-07 no tienen prueba. Cobertura estimada: 0 % en la capa DTF. |
| #120, `974128e5` y `8bacc925` | Aprobado con observaciones | **Tarea 4:** P120-01 baja de **Alta a Media** (detalle abajo). |
| #121, `59c16146` | Aprobado con observaciones para el commit | Las pruebas de SEG-T405-01 y 03 sí fallarían sin la corrección. P121S-04 y P121S-05 (importación en vista previa y 51399 con varias cuentas) siguen abiertos. |
| #126, texto de las firmas (ya unido) | Aprobado con observaciones | **P126-01:** la línea «DP-2 … provisionalmente (C)» no tiene respaldo; lo firmado es A, y el bloqueo de la (e). **P126-02:** las condiciones de DP-3 no son las cinco de la sección 3.5. **P126-03:** a DP-2 le faltan la marca de DF-02 y la línea de DF-01. **P126-05:** el choque con D1 no es T1-1 a T1-4. Todo eso va en un PR de seguimiento, solo de documentos. |

## 3. Plan de pruebas de N-1: `traspasos/C/2026-10-20-plan-pruebas-n1-api-servicio.md`
- **Orden del middleware:** se controla con una tabla de reglas «A antes que B» sobre el texto de `Program.cs` (`OrdenProgramaApiTests`). `WebApplicationFactory` no sirve, porque exige SQL.
- **Hallazgos:**
  - `UseLicencia` deja pasar las peticiones cuando el endpoint es nulo. Un `UseRouting` posterior abriría la licencia; lo impide la regla R9.
  - La API lanza Chrome o Edge para el PDF (`ConvertidorPdf.cs:66-82`), en contra de la premisa de A de que no hay `Process.Start`.
  - SQL, el anillo y la licencia se cargan antes de `app.Run()`, dentro del límite de arranque del servicio, sin dependencia de SQL ni reintento.
  - Sin PR-4, el servicio escucha en el puerto por omisión de Kestrel.
- **Lo que solo se puede probar instalando:** una lista de laboratorio, L-01 a L-17, en una VM.
- **8 preguntas para B.** Bloquean P-1 (clase aparte para el registro del servicio), P-2 (franja de EventId), P-3 (forma de fallar) y P-4 (el puerto). En **P-7**, C se ofrece a escribir los grupos A y B en un PR apilado sobre `b/n1-api-modo-servicio` para el 27-oct, si B responde P-1 a P-3 antes del 24-oct.

## 4. P120-01: baja de Alta a Media
- `974128e5` sigue el patrón de T3-07 y es más estricto.
- Pero `Abrir` no lanza: devuelve `ProblemaSeguridad`, y el 4740 depende de que el llamador lo revise.
- Si se quita la llamada en `Abrir` (`LlaveFirmaTokens.Windows.cs:187`) o la relectura en `Crear` (`:237-254`), **ninguna prueba falla**. Solo lo cubre el ensayo D6, que hace `return` sin administrador o sin TPM.
- **Pasa a Baja** si B agrega P120S-01 (una costura `internal` en el almacén del usuario, sin administrador) o registra la ejecución del ensayo D6 con equipo, fecha y resultado.

C queda sin trabajo en curso.
