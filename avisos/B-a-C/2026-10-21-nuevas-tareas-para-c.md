```
Para: C        De: B        Fecha: 2026-10-21
Tipo: Encargo (cola de tareas nuevas) y decisiones sobre la entrega del PR #132
Prioridad: Media
Repositorio y rama: GPOS-NG PR #132 (`c/n1-pruebas-orden`), #127 (`b/n1-api-modo-servicio` @ 7afa929d), #122 y #130 (A)
Estado: Abierto
```

# Cola de tareas nuevas para C (2026-10-21)

Reglas de siempre: filtros por clase, **sin suites completas ni cargas SQL en OSHIN-LEGION**, sin instalar servicios, commit y push frecuentes (el equipo es inestable). Nada se une sin orden expresa del propietario.

## Decisiones de B sobre la entrega del #132
1. **S1 con systemd:** se queda como está. Hoy systemd no existe (`La_API_no_tiene_otra_logica_de_servicio` lo prohíbe); si ADR-129 lo implementa, esa decisión y la regla S1 se cambian juntas.
2. **B-07 adaptada** (atributo `[SupportedOSPlatform("windows")]` en lugar de archivos `*.Windows.cs`): aceptada.
3. **Dos pruebas de orden:** conviven. La mía fija la lista; las de C fijan las razones. Si una cambia, el PR que mueve el orden actualiza las dos y lo dice.
4. **Grupo C (C-01, C-02, C-04, C-05, C-06, C-09 y C-11):** para el desarrollador de B, como dice su entrega. No lo toman.

## Tareas, por orden

### 1. Rediseño del laboratorio de ADR-90 con VirtualBox (ya encargado)
Ver `2026-10-21-virtualbox-en-lfmb-confirmado.md`. Se mantiene como su tarea principal. La tabla «bloque → VM → memoria» primero, porque define si la fase 1 cabe en `LFMB` (13,9 GB).

### 2. Rebasar el #132 y agregar la guarda de lo transitorio
- **Rebase:** el #127 tiene un commit nuevo (`7afa929d`, solo un comentario). Rebasar `c/n1-pruebas-orden` sobre él.
- **Guarda nueva** (un caso en el grupo A o en `ApiModoServicioArquitecturaTests`, a su criterio): **`Program.cs` no puede cablear `ArranqueRed` (RT-01) y conservar `FijarEscuchaPorOmision`.** Hallazgo de B en la revisión del #122/#130: `UseUrls` escribe `urls` en la configuración, y con el modo presente `ArranqueRed.Evaluar` lo rechaza con 4744. Debe fallar con un mensaje que diga que PR-4 retira esa línea. Hoy pasa (`ArranqueRed` aún no está en `Program.cs`).
- **Entrega:** el mismo PR #132. Plazo: **2026-10-27** (el que ya tenían).

### 3. Revisión de pruebas del #130 (RT-06) y del #122 actualizado
Es lo que hicieron con el #122 en la primera ronda. Revisen la cobertura de **#130** (`FiltroOrigenNodoTests`, `OrigenNodoTests`, `IpConexionApiTests`, `RutasSyncArquitecturaTests`, `RechazoOrigenNodoTests`) y las correcciones nuevas del **#122** sobre `e53b71a3` (es A quien las subió; B ya revisó el contrato).
- Qué buscar: pruebas que no fallarían si se quitara la línea que protegen (como hicieron con P120-01), uniones reales de reenvío (`ForwardedHeaders_Enabled`, IIS), IPv6 con ámbito, la muestra de 60 s con el reloj, y el filtro sobre rutas con `PathBase`.
- **Entrega:** informe en `traspasos/C/` y un comentario en cada PR. Plazo: **2026-10-28**.

### 4. Revisión crítica de las pruebas del #127 (las de B)
B escribió `ModoServicioApiTests` y reescribió partes de `ApiModoServicioArquitecturaTests`. Revísenlas como lo harían con cualquier PR de B:
- ¿Fallaría alguna si se quita la llamada a `ComprobarArranque`, si se invierte el orden identidad/privilegios, o si `Rechazar` no sale con código 1?
- ¿Qué parte del ciclo (`CicloDeVidaServicio`, `Rechazar` con el registro propio) no tiene ninguna prueba? Díganlo; B decide qué cubrir y qué deja al laboratorio.
- **Entrega:** informe en `traspasos/C/` y comentario en el #127. Plazo: **2026-10-29**.

### 5. PR de seguimiento de documentos por sus observaciones P126-01 a P126-05
Su revisión del #126 (ya unido) encontró texto sin respaldo: «DP-2 … provisionalmente (C)», las condiciones de DP-3, la marca de DF-02 y la línea de DF-01 de DP-2, y el choque con D1.
- Preparen el PR **solo de documentos**, sobre `master`, con la **fuente viva** de cada firma (las hojas de decisiones y el chat citado en ellas), según la regla del 2026-10-20 de no dejar texto que dé por pendiente lo firmado.
- Cada corrección cita la hoja o la línea del registro de firma que la respalda. Si una observación no se puede respaldar en una fuente firmada, **no se corrige**: la dejan como pregunta para B y para el propietario.
- B revisa y une (con orden expresa del propietario). Plazo: **2026-11-03**.

## Lo que sigue en otras manos
- Grupo E (al unir PR-4 de A) y los grupos D y F con el laboratorio, para el devops de B.
- La suite filtrada sobre el #132 la corre B en `LFMB` hoy.
- Plan de pruebas de las solicitudes de los titulares y del acceso del SUPER por caso (ADR-92): cuando A entregue sus respuestas a las preguntas técnicas. Les aviso.

Respuesta requerida: acuse con fechas, y el hallazgo que quieran subir antes que las fechas.
