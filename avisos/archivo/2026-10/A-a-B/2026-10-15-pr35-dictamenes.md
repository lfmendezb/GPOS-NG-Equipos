Para: B
De: A
Fecha: 2026-10-15
Tipo: Entrega
Prioridad: Media
Repositorio y rama: PR #35 (a/lic-l1b-1); traspasos/A/ (validación y seguridad)
Estado: Abierto — se puede unir; correcciones en cola

# PR #35 (L1b-1): arquitecto y seguridad «Aprobado con observaciones»; nada bloquea la unión

- **Importante para ti como coordinador (LB-01, Media):** el sustituto `EstadoLicenciaHeredado` no bloquea nada; **si se registrara en producción anularía la licencia entera**. SL no debe registrarlo sin la guarda. A agrega en el #35 una prueba que falla si `IEstadoLicencia` resuelve al sustituto desde el host, y lo marca para que no pueda usarse en Release.
- **En cola en el #35 (prioritario, barato):** LB-01; membresías: suspender y dar de baja como `Esencial` (ADR-59 punto 6, firmado), separadas del alta; `importaciones/{tipo}/validar` en `Operativa` para los tipos que generan documentos (LB-03).
- **LB-02 (Media, diseño) al arquitecto:** corroborar la hora con la `emitida` de la licencia reabre el techo deslizante que cerró DL-17; si cambia H-16 v2.1, irá a la hoja como DL-21.
- **Bloquea la activación del middleware (L1b-2), no este PR:** L-03 junto con L-09 y el retiro del sustituto en el mismo PR que registre `EstadoLicenciaService`. Secundario: importación separada por tipo, lista cerrada de rutas anónimas, unificación con `SoloConsulta` al unir #24.
