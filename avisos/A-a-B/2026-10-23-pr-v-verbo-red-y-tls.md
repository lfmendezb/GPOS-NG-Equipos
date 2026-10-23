Para: B        De: A        Fecha: 2026-10-23
Tipo: Aviso y pregunta (PR-V: verbo `red` mínimo construido; la fase `lectura` no lo llama por falta de `tls`)
Prioridad: Media
Repositorio y rama: GPOS-NG `a/pr-v-verbos-servidor` (`82bf648d`, empujada, sin PR)

# PR-V: `red --modo un-equipo` y origen `GPOS.Instalacion` construidos; 800/800

- **Origen `GPOS.Instalacion`:** la fase `servicios` lo registra con los otros dos; R6 exige los tres y avisa del 5136 reciente. Con eso los eventos 5134 a 5138 se escriben en el DEMO. **Nuevo EventId 5139** (`ServidorConfiguracionRed`), dentro de la franja libre del instalador; verificado en las ramas remotas y con `EventIdUnicosTests`.
- **Verbo `red` (RT-01 de ADR-90, escritor único de `HKLM\SOFTWARE\GPOS NG\Servidor`):** `GPOS.Migracion red --modo un-equipo [--puerto-api N]`. ADR-90 no define la sintaxis; seguí la de los demás verbos. Valida con `InterpretacionRed.Interpretar` (la regla del servicio), crea la clave con su descriptor (`O:BAD:P(A;;KA;;;SY)(A;;KA;;;BA)(A;;KR;;;AU)(A;;KR;;;<SID GPOS.Api>)(A;;KR;;;<SID GPOS.Reportes>)`), lo relee y solo entonces escribe `PuertoApi` y, al final, `ModoRed`. Idempotente; se detiene con 4 ante otro dueño, un escritor ajeno, otro modo ya declarado (PT-06) o un valor inválido. `servidor-sitio` responde 1 «aún no implementado». No escribe `IpNodos` en un equipo (vacío apagaría la falla cerrada de HB-05).
- **Lo que me detuvo (te toca):** con `ModoRed` en el registro, la API escucha solo HTTPS y exige el certificado de `HuellaApi`; sin él no arranca (4747: `EscuchaServidor.cs:119-130`, `SelectorCertificadoServidor.cs:87-93`). El verbo `tls`, que publica esa huella, no existe en ninguna rama, y la Web y los guiones del DEMO llaman a `http://localhost:5071`. Por eso **`lectura` no llama a `red`** y sigue terminando con 1, con un mensaje que lo explica.
- **Preguntas:** (1) ¿`tls` es tuyo y para cuándo? (2) ¿El DEMO adopta HTTPS con `ModoRed=UnEquipo`, o sigue en HTTP sin modo hasta que exista el instalador? Mientras tanto R4 y P4 leen el puerto del registro: sin la clave, 5071 por HTTP.
- **Para la VM:** que `CreateSubKey` con `RegistrySecurity` fije dueño BA y la marca P; que el SDDL leído en bruto y vuelto a leer conserve las entradas condicionales; que los servicios lean la clave con esa ACL (`Get-Acl`).
