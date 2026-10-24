Para: B        De: A        Fecha: 2026-10-24
Tipo: Hallazgo (D-5 (c), hueco [I] del registro de la empresa «pendiente»; tanda 10, puntos 2 y 3)
Prioridad: Alta (bloquea el paso de empresa y cuentas de PR-D2)
Estado: Abierto

# El hueco existe: ningún verbo de `GPOS.Migracion` registra la empresa «pendiente»

Verificado en `a/pr-d2-manifiesto` @ `6b691b46`:

- `aprovisionar --empresa X` lee la fila con `EmpresasSistema.ConexionAsync`: si **no hay fila** falla con «La empresa X no está registrada en GPOS_SYSDATA» (`EmpresasSistema.cs:51`); solo si la fila existe con `ConexionCifrada = ""` entra por la rama «pendiente» (`--servidor` y `--base`).
- Las únicas escrituras de `dbo.Empresas` son `EmpresasService` (alta desde la Web/MAUI/API, que exige sesión y por tanto cuentas ya creadas) y `GuardarConexionAsync` (`UPDATE`, exige fila previa). En modo servicios, antes del primer inicio de sesión, **nadie inserta la fila**.

**Propuesta (decide B/propietario; no implemento hasta tu aviso):** `aprovisionar --empresa X --descripcion "…" --servidor S --base GPOS_X` inserta la fila `(Codigo, Descripcion, Prioridad = 100, ConexionCifrada = "", Inhabilitado = 0)` si no existe (idempotente: si existe, no la toca) y sigue con la rama «pendiente». Ventaja: un solo verbo, respeta D-5 (c) (sysadmin del instalador, la API sin `dbcreator`) y no abre un verbo nuevo. Alternativa: verbo `registrar-empresa` aparte (más superficie, misma lógica). Recomiendo la primera. Pide una precisión sobre `--descripcion` obligatoria solo cuando la fila no existe.

**Orden interno de `FaseEsquema` (SF-03), tal como lo pides, con tu nota de F1 `c0144f3b`:** `sistema --login-api` → `anillo --anclar` → `sistema --cuentas-iniciales --confirmar-sellado`, tratando el 2 del primer `sistema` como normal solo si la salida trae la línea «Pendiente: … anillo --anclar». La empresa (`aprovisionar`) va después de `esquema` y antes de `lectura`, como firmó D-5. El blueprint 3.3 no necesita corrección por esto; lo confirmo al escribir el paso.

**Dependencia:** el paso se escribe sobre F1 unida (#228); `a/pr-d2-manifiesto` aún no trae `c0144f3b`. Empiezo cuando esté unida (5 al 9-nov, tu fecha) o rebaso sobre la rama de F1 si prefieres adelantar.

Respuesta requerida: elegir la propuesta (aprovisionar inserta) o la alternativa, y si rebaso ya sobre F1.
