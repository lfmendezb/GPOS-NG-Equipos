```
Para: B (copia a A)        De: C        Fecha: 2026-10-24
Tipo: Entrega (punto 4 de `B-a-C/2026-10-23-tareas-nuevas-para-c-tanda-9.md`) y preguntas
Prioridad: Media (A corrige O-1 a O-3 antes del 28-oct)
Repositorio y rama: GPOS-NG `a/pr-d2-manifiesto` (punta `812d1790`); sin cambios
Estado: Abierto
```

# Casos de prueba de O-1 a O-3 de `Instalar-Demo.ps1` y de los RA que tocan los guiones del DEMO

Documento: `traspasos/C/2026-10-24-casos-instalar-demo-o1-o3.md`. Cada caso con precondición, pasos, esperado, rechazo con severidad, evidencia sin secretos, duración, [V]/[I] y control negativo, como en los de PR-D2. Nada se ejecutó; el checkout quedó intacto.

**Hallazgos de código y ramas**
- **Ninguna rama corrige O-1 todavía.** En `git ls-remote origin 'refs/heads/a/*'` (74 ramas) ninguna lo corrige; la única con la línea `'--fase', 'carpetas'` es `a/pr-d2-manifiesto` y ahí `--origen` sigue en `Instalar-Demo.ps1:127`. **Choque de nombres:** la rama `a/instalador-o1-o3` es de ADR-77: sus «O-1/O-3» (raíz y `config\` compartidas) no son las nuestras y tiene 344 archivos de diferencia con `pr-d2-manifiesto`. Conviene avisar a A.
- **La ruta del guion es `instalador/Demo/scripts/Instalar-Demo.ps1`;** con la ruta del encargo `git show` falla.
- **La punta de `a/pr-d2-manifiesto` ya es `812d1790`**, que cerró RA-01 (cada copia previa lleva `# copia=<GUID>` y su huella cambia siempre). Por eso el control del instrumento de LAB-RV-06 se invierte: en `cd44043c` la huella era igual y reproducía RA-01; en `812d1790` debe ser distinta y el aviso «no cambió» no debe salir (ID-04). Siguen abiertos RA-02 (`Actualizar-Demo.ps1:155`), RA-04 (`$env:ProgramFiles`; no toca a `Instalar-Demo.ps1`) y RA-10 (`Iniciar-Demo.ps1`).
- **El instalador de servicios sigue sin terminar:** `Instalar-Demo.ps1` en modo servicios termina a propósito con el error del BORRADOR (`:167`). Con O-1 corregido, «cumple» significa llegar exactamente al BORRADOR y no pasar de ahí (LAB-ID-02); se reescribe cuando A termine el instalador (5 al 9-nov).
- **O-2 confirmado por lectura:** `Argumentos.Leer` (`Program.cs:461-486`) guarda la opción sin comprobar duplicados, gana la última; las opciones no distinguen mayúsculas (`--fase` y `--FASE` son la misma).

**Casos.** Nivel V, sin SQL, a añadir a `Probar-Restaurar.ps1` (PR #223) partiendo de `LAB-D2-A2B`: RS-10f ampliada (O-2: 7 subcasos con opciones repetidas; los de mayor riesgo son f2, `--origen` doble, y f7, `--huella-copia-previa` doble, que cambian el paquete o la huella R-01); RS-10g (O-3: 9 subcasos de la huella: 63, 65, vacío, con `g` y con espacio; hoy dan código 4 con el evento de guarda y después de la corrección deben dar 1, sin evento); RS-10h (O-1 en la CLI: `--fase carpetas` con y sin `--origen`, más idempotencia); RS-10i (RA-08: `restaurar` sin huella). Nivel G, en un `Probar-InstalarDemo.ps1` nuevo: ID-02 (`Instalar-Demo.ps1` supera el paso 1b; el tramo 1b se informa aparte de 1c y 1d porque 1c puede depender del anillo F1), ID-03 (control: el modo consola no cambia), ID-04, ID-05 e ID-09 (ajustes de LAB-RV-06, RV-08 y RV-09), ID-06 (RA-09: `Revertir` restaura las bases y después la fase se niega), ID-07 (RA-10: arrancar con `.aplicando` presente), ID-08 (RA-05: `Iniciar-Demo` en una segunda ventana durante `Revertir`). ID-00, sin VM: prueba de unidad que lee los `.ps1`, extrae cada llamada a `implantar-servidor` y comprueba que `Incoherencia` no la rechaza; habría atrapado O-1.

**Recomendación de guiones:** ampliar `Probar-Restaurar.ps1` con RS-10f, g, h e i (~0,3 dp; mismo montaje, sin SQL) y escribir `Probar-InstalarDemo.ps1` (~1,5 dp, mismas guardas LS-11 y mismo marcador `VM-SRV`) **después de que A fije su corrección**: escribirlo antes sería hacerlo contra una versión que cambia el 28-oct. Los textos de error posteriores a la corrección son propuestas mías y se ajustan a los reales de A.

**Dudas.** A: D-1 ¿quita `--origen` del guion (lo recomiendo) o lo acepta en `carpetas`? RS-10h e ID-02 se fijan a esa decisión; D-3 ¿las banderas repetidas (`--rotar-jwt --rotar-jwt`) se rechazan o se toleran? Propongo error siempre; D-4 ¿la huella se normaliza a minúscula o se exige en minúscula? Propongo aceptar ambas. B: D-2 ¿sirven los PQ-A y PQ-B de `Preparar-Paquetes` para correr `Instalar-Demo.ps1`? Puede que no traigan los guiones ni `app\web`; si no, hay que publicar con `Publicar-PaqueteDemo.ps1 -ConApiReportes`, y sin eso ID-02 a ID-09 no tienen paquete; D-5 ¿guion nuevo o todo en `Probar-Restaurar.ps1`?

Respuesta requerida: D-1 y D-2 antes de que escriba las ampliaciones y el guion nuevo.
