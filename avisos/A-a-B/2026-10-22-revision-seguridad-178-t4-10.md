Para: B        De: A        Fecha: 2026-10-22
Tipo: Entrega (revisión de seguridad del documento de T4-10, #178, punta `bad7714b`)
Prioridad: Media
Repositorio y rama: GPOS-NG #178 `b/datos-t4-10`

# #178: Corregir (Rechazado en su forma actual; un hallazgo Alto de arreglo barato)

Informe: `traspasos/A/revision-seguridad-pr178-t4-10-2026-10-22.md` (revisión estática del auditor-seguridad sobre el documento; verifiqué yo S178-01 y S178-02 en el código de `feature/modelo-ng`). Con S178-01 incorporado pasa a **Aprobar con condiciones** (S178-02 a S178-04).

**Bien aplicado:** sello HMAC con `Huella binary(33)`, guardado en dos pasos y falla cerrada; S-02 con su CHECK y 51641; C-1′, S-04 y S-05 (revisó las 45 vistas: ninguna entrega la cédula completa por otra columna ni por una unión); C-2′ con el cuadre partido por `Tipo`; `GRANT`/`DENY` contra `PermisosLecturaReportes.cs`; sin `SELECT *` ni SQL dinámico; 5150 a 5154 y 51639 a 51641 libres.

**Alto**
- **S178-01 — C-2′ se evade por las rutas JSON del cierre.** El documento aplica `vercuadrecaja` a la impresión, la reimpresión y el correo, pero `POST /cierres/x` devuelve el cuadre completo a quien solo tiene `cierrex` (`EfectivoEndpoints.cs:80`), `GET /cierres/{numero}` lo da al dueño del turno sin `cuadrecaja` (`:76-78`) y la lista `GET /cierres/` muestra `TotalVentas` y la diferencia. Un cajero ve lo esperado y la diferencia y puede ajustar lo que declara en el Z. Remedio: sin `vercuadrecaja`, esas rutas responden sin montos, con línea en la bitácora, y la prueba 21 se amplía. Si el propietario quería C-2′ solo para el impreso, debe confirmarlo sabiendo que así el control no protege nada.

**Medios**
- **S178-02 — el `otp` de la ruta de sellado puede fallar abierto.** El documento remite a `AutenticacionIntrospeccion` (`SinFactorExigido`), que solo exige el `otp` si la principal manda `ExigeOtpSuper` [V]; mi diseño del sello pide `otp` sin condición. Tampoco dice qué pasa si falta `auth_time`.
- **S178-03 — el sello no está atado a la empresa ni se puede revocar uno solo.** Una sola llave por instalación: quien escriba en `conf.FormatoImpresion` puede restituir un Razor sellado anterior o copiar uno de otra empresa con el mismo `Id`. Remedio: la empresa del contexto de la petición entra al mensaje; «revocar un Razor = rotar `Kid`»; y el propietario firma el riesgo de repetición (hoy solo lo aceptó un equipo).
- **S178-04 — el conteo a ciegas queda expuesto:** `imp.ConteoLinea` entrega `ExistenciaCorte` y `Diferencia` sin privilegio (S-10 sigue aplazado). Entregarlas solo con la captura cerrada.

**Bajos (S178-05 a S178-12):** en compra y constancia la identificación sale del maestro vigente (al reimprimir puede salir completa otra cédula); `DEV` en dos vistas de encabezado; el 51639 se usa en dos comprobaciones; la franja de `imp` (51639-51644) no está anotada en ADR-82 (la de D1 llega a 51638); el 5152 tiene nombres distintos en tu documento y en mi diseño (`FormatoSelloRechazado`; lo adopto); **5130-5133 y 5140-5143 ya están en uso dentro de la franja 5130-5149 reservada al instalador (N-8)** — choque previo, ajeno a T4-10, que afecta a mi propuesta de 5130-5134 para PR-V: te pido que fijes qué parte de la franja queda libre; la ruta de impresión del cierre de la principal no comprueba la sucursal.

**De A:** el `Papel` entra al mensaje del sello si el render lo compila (lo señalé como condición en mi diseño) y adopto el nombre 5152.

Revisión previa (S-01 a S-09): S-01 a S-05 y S-07 a S-09 cerrados; S-06 parcial (solo comprobable en T4-11); S-10 abierto.

Respuesta requerida: B incorpora S178-01 a S178-04 en la revisión 4; reviso solo esas secciones.
