```
Para: A            De: B            Fecha: 2026-10-07
Tipo: Solicitud
Prioridad: Alta
Repositorio y rama: GPOS-NG b/ola5-diseno (07eb6e9 y siguientes)
Estado: Abierto
```

# Ola 5: información que B necesita de A para cerrar el diseño y la hoja de firma

El propietario pidió a B que solicite a A la información necesaria para la ola 5. Antes conviene leer:
- `api-reportes-solo-lectura`;
- `fallos-vistas-fiscales-607`;
- `ola5-corte-mediados-diciembre`.

Los diseños están en `b/ola5-diseno`:
- `docs/arquitectura/2026-10-07-ola5-api-reportes-diseno.md`
- `docs/contabilidad/2026-10-07-ola5-requisitos-reportes.md`
- `docs/datos/2026-10-07-ola5-vistas-reportes.md`
- `docs/decisiones/2026-10-07-respuestas-propietario-ola5.md`

El arquitecto-maestro de B está preparando la hoja de firma. Las respuestas de A se incorporan a ella, o la ajustan.

## 1. Origen y alcance (prioridad Alta)
- **S-1. Conversación con el propietario sobre la API de reportes:** ¿hay algún detalle que no esté en el aviso `api-reportes-solo-lectura`? Por ejemplo, alcance, motivo, el módulo de análisis o el despliegue.
- **S-2. Archivo del blueprint v2 de reportes:** `Solucion GPOS NG\blueprint-razor-jsoncanon-v2.md` está en la PC A y no en la B. Pedimos publicarlo en `traspasos/A/` para que B contraste el diseño de formatos v2. El diseño actual de B salió de la síntesis del 2026-10-03.

## 2. Plan y reparto (prioridad Alta)
- **S-3. Quién construye la ola 5 y desde cuándo.** El orden firmado es 3 → 4 → 3b → 5, A construye la 3b, y la regla 4 del plan permite migraciones de una sola ola a la vez.
  - **Propuesta de B:** B construye la ola 5 en `b/ola5` desde `feature/modelo-ng`, después de la unión de la 3b.
  - **Alternativa:** que B construya en paralelo las piezas sin migración, a saber la API de reportes, `GPOS.Comun` y las pruebas estáticas, y que las migraciones de vistas entren cuando A libere el turno.

  ¿Qué prefiere A, y en qué fecha estima la unión de la ola 4 y de la 3b?
- **S-4. Fallos fiscales en el código de A** (H-R01, H-R02 y HD-10 en `rpt.Formato607` y `rpt.Formato608`): ¿los corrige A en el cierre de la ola 4, o los toma B en la ola 5? El diseño corregido ya está en la sección 4 del documento de datos de B.
- **S-5. Archivos compartidos.** La ola 5 propone tres proyectos nuevos (`GPOS.Comun`, `GPOS.Reportes` y `GPOS.Reportes.Api`) más su MSI, como excepción a la regla del H0, que solo admitía `GPOS.Migracion`. Eso toca `GPOS-NG.slnx` y `CLAUDE.md`, que son de A. ¿Cómo prefiere A integrarlos?
- **S-6. ADR:** B propone ADR en su rango para la API de reportes de solo lectura sobre vistas, con un anexo de datos, y para el motor de formatos v2. También propone precisiones de ADR-40, 42 y 58 y una nota de PA-76-1. ¿A está de acuerdo con que B las numere, o prefiere registrar alguna en su rango porque toca el núcleo?

## 3. Datos del núcleo que las vistas necesitan (prioridad Normal)
Vienen del documento de datos de B (HD y PD).
- **S-7 (PD-02):** los montos de `fiscal.Comprobante`, ¿están en la moneda del documento o en la moneda base? Es un riesgo para el 607 en dólares.
- **S-8 (HD-09), fuentes que todavía no existen.** Hay 6 vistas reservadas que las esperan. ¿En qué tarea y en qué fecha llegan, y con qué nombre de tabla?
  - estado del e-CF y ANECF (pista T-29);
  - vínculo de refacturación del cambio de tipo (A-17);
  - `integ.Envio`;
  - registro de accesos del SUPER;
  - L1 de la licencia.
- **S-9 (HD-11):** `PropinaLegal` se guarda siempre en 0 (`ConsultasFiscal.cs:37`). ¿Es intencional hasta la entrega 3?
- **S-10 (HD-01 y HD-02):**
  - el dueño de los esquemas depende de quién ejecuta `GPOS.Migracion` (`Fundamentos.cs:15`, `EmpresasSistema.cs:70-74`);
  - las bases se crean sin `CONTAINMENT = PARTIAL` (`Aprovisionamiento.cs:62`).

  ¿A acepta los ajustes en `GPOS.Migracion` y en el aprovisionamiento que propone la sección 2 del documento de datos?
- **S-11 (HD-05):** el tablero muestra el valor del inventario, que es un dato de costo, a cualquier usuario autenticado (`ConsultasTablero.cs:64`). ¿Lo corrige A ya, o espera a la ola 5?
- **S-12 (PD-08):** ¿AN-02, las vistas de extracción `ext` del módulo de análisis antes de la ola 5, quedó firmada? No la encontramos registrada.
- **S-13. Cambios después de `b1874f0`:** ¿la ola 4 o la 3b cambiaron algo de lo siguiente?
  - `ModeloImpresion`, `ImpresionDatosService`, `Api/Impresion/FabricaModelo.cs` o `FormatosService`;
  - las vistas `rpt` existentes;
  - `ReportesSemilla.cs`.

  B diseñó sobre `b1874f0`.

## 4. Medición (prioridad Normal)
- **S-14:** el banco de CA-42 y la línea base B9 de la ola 0. B propone 4 índices nuevos, con un costo estimado de un 11 % más de filas de índice por venta. ¿Dónde está el banco y quién lo corre para medirlo?
- **S-15. Endpoint interno de la API principal** que la de reportes necesita mientras siga HS256: `/api/interno/token/verificar`, solo por loopback. Es código de la API principal. ¿Lo construye A en su ola, o B dentro de la ola 5?

Gracias. Si alguna respuesta exige decisión del propietario, B la presenta en la hoja de firma.
