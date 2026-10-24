Para: C (copia para A)        De: B        Fecha: 2026-10-24
Tipo: Aviso (F1 corregida) y encargo
Prioridad: Alta (la ventana de laboratorio de hoy y mañana depende de esto)
Repositorio y rama: GPOS-NG [#228](https://github.com/lfmendezb/GPOS-NG/pull/228), `b/f1-anillo` @ `26f54eaa` (empujado)
Estado: Abierto

# F1 corregida: SF-01 a SF-04 y SF-06

Cinco commits sobre `e1c6f516`, uno por hallazgo. Verificado por mí en el worktree: árbol limpio, **442 de 442** en Anillo y Criptografía (antes 430). El agente informa además 625/625 en arquitectura, 15/15 en `Rg14Lote2b`/`Dl02` y 8/8 en `QaOla1SitioHttp`/`ApiModoServicio`; esas tres cifras son suyas, no las repetí.

- **SF-01:** `--migrar` y `--cambiar-recuperacion` exigen `--huella-recuperacion`; `--cambiar-recuperacion --recuperacion <cer>` publica el `.cer` nuevo de forma atómica en `config\GPOS.Api.recuperacion.cer`. Exigí la huella en `--migrar` **también con ancla** (tú la pedías solo sin ancla). **Amplía SA-01: pendiente de firma del propietario.**
- **SF-02:** G-1 cubre todo `sistema`.
- **SF-03:** con el anillo con certificado y sin ancla en regla, `sistema` aplica esquema, S1 y marca, informa «Pendiente», **no escribe `InstalacionId`** y sale con **2**; `InstalacionId` y el sellado se completan en `sistema --cuentas-iniciales --confirmar-sellado` tras `--anclar`. También sale con 2 si el ancla está en `NoVerifica` o `RecuperacionCambiada`.
- **SF-04:** sin archivo del anillo y sin poder leer la fila del ancla, la API no arranca (4704). Excepción: SQL 4060 o 208 cuenta como «sin ancla» para no romper el primer arranque de Debug o DEMO.
- **SF-06:** pruebas del cableado de G-1 y G-2 (MC-23 y MC-24 muertas por mutación a mano).

**Para ti:** repite SF01a, SF01b, SF02, SF03 y SF04, y MC-23 y MC-24, sobre `26f54eaa`. Revisa en especial las dos decisiones del agente: la salida 2 como estado esperado del primer `sistema`, y la excepción 4060/208 de SF-04 (4060 también aparece si el login de la API no tiene acceso a la base). Lo tuyo de SF-07 (pruebas de mutantes vivos) sigue en tu tanda 10, punto 2.

**Para A (copia):** en `FaseEsquema` (PR-D2), la salida 2 del primer `sistema` es normal si el anillo con certificado aún no tiene ancla; no la trates como error. La revisión de seguridad de F1 se hace sobre `26f54eaa`.

Respuesta requerida: tu informe sobre `26f54eaa` (fecha propuesta: 25-oct).
