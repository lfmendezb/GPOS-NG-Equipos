Para: A        De: B        Fecha: 2026-10-22
Tipo: Autorización del propietario, decisiones registradas y orden de unión
Prioridad: Alta
Repositorio y rama: GPOS-NG #137, #139 y #140; plan del DEMO
Estado: Abierto

# Autorización de subir la deuda al #140 y orden de unión

El propietario autorizó en el chat (2026-10-22): «Autorizo que A suba los 9 commits de la deuda más R4-02 al #140 y que se una en este orden: #137, luego #139 y #140 juntos, pasando primero a listos. Procede con gh pr merge cuando A avise.»

## Qué hace A
1. **Sube al #140** los 9 commits de `b/deuda-pr2-p137-p140` (ya cherry-picked en tu árbol) **más R4-02** y, en commits aparte, el comentario de `TargetHost` y el campo `internal static readonly` de P140-01 (tu alternativa al constructor, que se acepta). Avísame con el sha de la punta.
2. B repite la suite filtrada sobre esa punta (ya corrió verde sobre mi rama: 4980 correctas, 4 inestables repetidas en verde) y, si el único cambio son tus pruebas y comentarios, la dará por buena con las pruebas dirigidas.
3. **Orden de unión (B, con `gh pr merge`):** #137; luego #139 y #140 **juntos**, pasándolos primero de borrador a listos y cambiando la base de cada uno a `feature/modelo-ng` tras unir el anterior.
4. Quedan fuera de la unión las Bajas R4-01 y R2-03, y la deuda de laboratorio TL-01/TL-02/TL-03 de C.

## Plan del DEMO con la API de reportes: decisiones del propietario, registradas
El propietario confirmó en el chat que aprueba **P-1, P-4, P-3 y P-7** (hoja de B: `docs/decisiones/2026-10-22-hoja-firma-demo-con-api-de-reportes.md`). Los acuses de B:
- **P-1:** 6,5 a 8 dp registrados. La capacidad de A desde el 3-nov (T4-06 y el token) se revisa en la reunión de prioridades de B antes del 3-nov.
- **P-4:** T4-06 conserva `CompilacionDepuracion` y no se une antes de PR-D1.
- **P-3:** sujeto al dictamen de seguridad de A.
- **P-7:** el perfil de Chromium pasa a `%ProgramData%\GPOS NG\Reportes\render`; B lo hace **condición de T4-02 y de T4-03** (la ACL de la cuenta del servicio la crea el instalador, que aún no existe), no cambio del #152.

Respuesta requerida: aviso de A con el sha de la punta del #140.
