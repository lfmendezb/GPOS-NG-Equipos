```
Para: A y C        De: B (coordinador)            Fecha: 2026-10-14
Tipo: Entrega
Prioridad: Alta
Repositorio y rama: GPOS-NG feature/modelo-ng 4ace678
Estado: Abierto
```

# T1 de ADR-126 (valores de terceros) unido a feature/modelo-ng (4ace678)

## Qué entra
`b/config-terceros` se unió con `--no-ff` sobre `ad6015d`. Commits:
- `c6b7193`: **A-01.** La URL del padrón RNC sale del código y queda en `GPOS:RncDgii:Url`, sin constante. Si falta o no es `https`, da un error claro.
- `f7d4690`: **O-3.** `TrabajoRncDgiiUrlTests`, con dos casos: la URL falta o es `http`. En ambos, el padrón no se toca (ni un cliente HTTP, ni temporales, ni filas).
- `9540cf8`: **VT-10, guarda de 5.7 (puntos 1 y 2).** `tests/GPOS.Tests/Arquitectura/ValoresDeTercerosTests.cs`, con `Esquema=Neutral`.
  - Falla ante cualquier URL, dominio `.gov.do`/`.gob.do` o IPv4 de un tercero en `src/`, `GPOS.UI.MAUI/` e `instalador/`.
  - La lista de excepciones solo decrece: también falla si una excepción ya no aparece.
- `143b561`: **E-01 y VT-09.** Roboto queda alojada en `src/GPOS.Web/wwwroot/fonts/roboto` (latin 300/400/500/700 de `@fontsource/roboto` 5.1.0, Apache 2.0, con descarga autorizada por el propietario). Ya no se usa Google Fonts.

## Verificación
- **Solución completa:** compila con 0 errores, Android incluido. Los workloads se instalaron tras el reinicio.
- **Pruebas:**
  - `Arquitectura` y `TrabajoRncDgiiUrlTests`: 151/151.
  - `GPOS.Web.Tests`: 610/610.
  - `Categoria=Mvp`: 22/22 en `.\SQLEXPRESS` y 22/22 en `.`, también antes de T1, tras la actualización de SQL Server.
  - La guarda se comprobó con un archivo trampa: falla como debe.
- El árbol unido es idéntico al de la rama probada.

## Qué cambia para A y C
- **Toda URL, dominio o IP nueva de un tercero en el código hace fallar `ValoresDeTercerosTests`.** El valor va en `appsettings.json` (ADR-126). Si es una excepción legítima, se pide a B con justificación.
- **En la lista inicial hay 19 excepciones** (A-02, A-03, A-04, D-01, D-02 y E-02), más tres hallazgos nuevos que no estaban en el inventario:
  - G-01: `GPOS.UI.MAUI/App.xaml:12`, un comentario `go.microsoft.com`;
  - G-02: `Platforms/Windows/App.xaml.cs:4`, un comentario `aka.ms`;
  - G-03: `instalador/Demo/Publicar-PaqueteDemo.ps1:30`, la ruta fija de 7-Zip.
- La guarda trae dos reglas que no figuran en 5.7: servidores de correo en minúsculas (para A-04) y las rutas fijas `Program Files` y `/usr/bin/` (para E-02). Están por confirmar con el arquitecto-integraciones.
- Las ramas que salen de `feature/modelo-ng` pueden traer `4ace678`. Solo agrega pruebas, recursos estáticos y una línea de `App.razor`.

## Pendiente
- T2 de ADR-126 (5 a 6 días-persona), antes del corte.
- Fijar la tanda de G-01 a G-03 y confirmar las dos reglas extra.
