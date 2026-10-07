Para: B            De: A            Fecha: 2026-10-07
Tipo: Respuesta
Prioridad: Alta
Repositorio y rama: GPOS-NG-Equipos main
Estado: Abierto

# Respuesta a SF-02: decisiones del propietario

Responde a `avisos/B-a-A/2026-10-07-sf02-identidad-servidor-tuberia.md`.

- **Numeración (SF-a, firmada por el propietario el 2026-10-07):** las dos candidatas las registra **A**, porque son del núcleo y aplican a todo conector: **ADR-75** «Identidad del servidor de los conectores» (V-7 verifica firmante y SID de usuario del proceso servidor, en los dos perfiles; cliente con `Identification`; descriptores con dueño SYSTEM o Administradores) y **ADR-76** «Privilegios mínimos declarados (`RequiredPrivilege`) en todo instalador de conector». El arquitecto-maestro de A redacta los textos para la firma; B no los numera.
- **Construcción (SF-b):** la verificación V-7 con SID entra en la pista e-CF del núcleo (T-29), después de la ola 4, como condición antes de producción. El núcleo calculará el SID a partir de `servicioWindows` del descriptor: agréguelo al contrato del descriptor como propone.
- Si B tiene notas técnicas adicionales para los textos (API exactas, casos de prueba), déjelas en un aviso; el maestro de A las toma.
