```
Para: B        De: A        Fecha: 2026-10-21
Tipo: Entrega (revisión de seguridad del #127, N-1; tarea 2 punto 2 del encargo)
Prioridad: Media
Repositorio y rama: GPOS-NG PR #127 (`b/n1-api-modo-servicio` @ 7afa929d); informe `traspasos/A/revision-seguridad-pr127-n1-2026-10-21.md`
Estado: Abierto
```

# Revisión de seguridad del #127: Aprobado con observaciones

Sin Críticos ni Altos; **el PR se puede unir**. **Pero la API no debe instalarse como servicio fuera del laboratorio mientras S-01 y S-02 sigan abiertos.** Solo lectura (no compilé ni ejecuté nada).

- **Bien:** el orden de `Program.cs` (identidad y privilegios en la línea 30, antes de la configuración, `Build`, el anillo y los datos; las pruebas lo fijan); `ARRANQUE_IDENTIDAD` y `ARRANQUE_PRIVILEGIOS` (SID nulo rechazado, cuentan todos los privilegios del token, código 1 y evento 4767); `IdentidadProceso` es el mismo código de la estación, movido. ADR-76 punto 4 se cumple.
- **S-01 (Media):** como servicio nada comprueba a qué direcciones se enlazó Kestrel (Reportes sí, N-01). Remedio: esperar a PR-4 antes de instalar, o una comprobación interina de 2 a 4 horas.
- **S-02 (Media):** HTTP en `localhost:5071` sin autenticar al servidor: un proceso local podría ocupar el puerto con la API caída y recibir las credenciales de la Web. Lo cierra el TLS de ADR-90 (PR-2/PR-4).
- **S-03 (Baja):** el modo servicio depende de detectar el Administrador de servicios y falla abierta ante un falso negativo (la estación usa `--estacion` y falla cerrada). Remedio: argumento `--servicio` desde el MSI. Un atacante local no puede forzar el modo servicio.
- **S-04 (Baja):** si falla la lectura del token o falta el origen de eventos, el servicio no arranca pero sin el 4767. **S-05 (Baja):** el filtro `GPOS*` en Información lleva usuario y origen al registro de Aplicación (`ModoServicioApi.cs:81`). **S-07 (Baja):** dos cálculos del SID de cuenta virtual (`IdentidadProceso` y `CuentaServicioVirtual`).
- **S-06 (para mi PR-4):** unificar el código de salida del rechazo de ADR-90 con el de N-1 (1), y retirar `FijarEscuchaPorOmision`.
- **Quién:** tu desarrollador, S-03, S-04, S-05 y S-07 en `ModoServicioApi` (menos de un día); devops, el origen de eventos en L-1/L-2 y la condición de instalación de S-01/S-02; el responsable de `AuthEndpoints`, no registrar tal cual `req.Usuario` en los intentos fallidos (`AuthEndpoints.cs:82`).
- **ADR-76 punto 2** sigue abierto hasta que el documento de operaciones pase a `docs/operaciones/` y L-9/L-10 confirmen el PDF bajo la cuenta virtual. **Ya corregí las secciones 8 y 9 del documento de operaciones** (S-01/S-02 nombradas, el filtro de registro y la comprobación del origen en L-2).

Respuesta requerida: ninguna.
