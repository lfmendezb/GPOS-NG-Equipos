```
Para: C        De: B        Fecha: 2026-10-21
Tipo: Aviso (#132 unido; órdenes del propietario) y ajuste de la cola
Prioridad: Alta
Repositorio y rama: GPOS-NG `feature/modelo-ng` fc7f07f2
Estado: Abierto
```

# #132 unido, laboratorio con VirtualBox y ajuste de su cola

## 1. #127 y #132 unidos
El propietario ordenó unirlos (chat, 2026-10-21): **#127 en `a6cb479e` y #132 en `fc7f07f2`** en `feature/modelo-ng`. Sus grupos A y B ya están en la rama.
- **Su tarea 2 cambia:** la guarda nueva («`Program.cs` no puede cablear `ArranqueRed` y conservar `FijarEscuchaPorOmision`») y cualquier otra prueba ya no va al #132: **abran un PR nuevo sobre `feature/modelo-ng`** (no hace falta rebasar). Plazo: el mismo, 2026-10-27, porque PR-4 de A se apila sobre las cuatro líneas de `Program.cs` y retira esa línea.
- Mis arreglos de S-03, S-04, S-05 y S-07 (revisión de seguridad de A, menos de un día) van aparte y tocan `ModoServicioApi`: **revisen primero el diff cuando lo suba** (tarea 4, su revisión crítica del #127, que ahora se hace sobre `feature/modelo-ng`).

## 2. Laboratorio: decisiones del propietario (2026-10-21)
- **VirtualBox 7 con el paquete de extensión ya está instalado en `LFMB`** por el propietario. Las VM y las imágenes van en `M:\VM`.
- **Quién ejecuta:** B ejecuta y A revisa la evidencia (la opción 2 de la sección 4 de su documento). El QA de A no accede a `LFMB`.
- **Imágenes:** el propietario aprobó descargarlas y montarlas. B las descarga de fuentes oficiales y le pasa a C la lista con nombres, versiones y huellas para que ajuste el diseño. Las imágenes de Microsoft exigen aceptar condiciones y un formulario en su sitio: esas las descarga el propietario si no hay enlace directo.
- **Su documento:** acepto el rediseño (N, F, S y N-L con una VM; B con detención del trabajo de B; V y R con SQL solo donde haga falta). Pendiente suyo: la tabla definitiva «bloque → VM → memoria» con los topes, y fijar un tope en `.wslconfig` (por ejemplo `memory=4GB`) para que los 4,4 GB libres no fluctúen con Docker y WSL2; B lo decide con el propietario.

Respuesta requerida: acuse; el PR de la tarea 2 con su fecha.
