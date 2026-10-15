# ADR-82 · Precisiones del 2026-10-15 para registrar (DL-22 y cierre de la frase de DL-02)

**Para quien registra (B), no se copia al ADR.**
- **Dónde va:** al final de `docs/adr/ADR-082.md` (registrado por B en `10712963`), después de las «Precisiones del registro (B, 2026-10-14)». El texto firmado de arriba no se toca.
- **Qué recoge:**
  1. **DL-22 (a) con plazo de 2 min** (lo pedido): precisión del punto 3 (D-04 (a)) y de T3-03 y PA-30 del diseño de datos.
  2. **DL-02 (a), firmada:** la frase del punto 9 que el registro marcó «pendiente de firma» queda firme. Se resuelve con una nota del registro, sin reescribir el punto 9.
  3. **Enlaces a ADR-83:** cuando se registre ADR-83, las tres menciones «ADR-83 (en borrador, sin registrar)» del encabezado, del punto 16 y de las notas de relación pasan a ser el enlace `[ADR-83](ADR-083.md)`. Es un cambio de forma, sin cambio de contenido.
- **Fuente:** hoja DL-01 a DL-22 **v2.13**, `traspasos/A/hoja-firma-dl01-dl13-licencia-2026-10-14.md` del área común, DL-22 y sección 7; `traspasos/A/validacion-rg14-lote2b-y-s1-2026-10-15.md`, sección B; `traspasos/A/revision-seguridad-pr39-rg14-lote2b-2026-10-15.md`, sección 5.
- **Fila del índice (`README.md`, fila 82), texto que se agrega:** «precisión del 2026-10-15 del punto 3 (DL-22 (a), 2 min): rotación de `gpos_app_a|b` con `DENY CONNECT` inmediato y `KILL` diferido obligatorio a los 2 min, `Connection Lifetime` ≤ plazo, `ClearPool` en la API, aviso de S4 y `--urgente`; DL-02 firmada: la frase del punto 9 queda firme».

---

> **Precisión del 2026-10-15 del punto 3: rotación de la credencial de la API en cada base de empresa sin `KILL` inmediato (DL-22 (a), con plazo de 2 minutos, de la hoja de firma DL-01 a DL-22 v2.13, en el área común `traspasos/A/hoja-firma-dl01-dl13-licencia-2026-10-14.md`\*; firmada por Leonardo Méndez, propietario, el 2026-10-15 en la sesión de B, respuesta literal: «Aprobado según la recomendación: Las firmas de licencia DL-01, 02, 03, 05 y las demás de la lista.»; la recomendación firmada: «2 min con `ClearPool`; subir hacia 6 si PA-30 muestra 500»; precisa también T3-03 y PA-30 del diseño `traspasos/A/datos-t3-12-rg14-2026-10-14.md` v2).** Es de RG-14, no de la licencia. Sin cambiar el texto firmado de arriba, «dos generaciones para rotar sin corte» se cumple así:
> 1. **Rotación normal** (`GPOS.Migracion credencial-app`): se crea la generación nueva, se escribe la cadena nueva de la empresa y se aplica `DENY CONNECT` a la generación anterior **de inmediato, sin `KILL` en el acto**.
> 2. **`KILL` diferido y obligatorio a los 2 minutos.** Pasado el plazo, `credencial-app` hace `KILL` de toda sesión que quede de la generación anterior y no termina hasta que no quede ninguna. Si la prueba PA-30 muestra errores 500 con 2 minutos, el plazo se sube hacia 6 minutos, dentro del rango firmado (2 a 6), y se informa al propietario.
> 3. **`Connection Lifetime`** en las cadenas de la API de cada empresa, igual o menor que el plazo (con 2 minutos, 120 s como máximo), para que el grupo de conexiones recicle las conexiones de la generación anterior antes del `KILL`.
> 4. **En la API:** al detectar el error 18456 de una empresa, además de olvidar la cadena, `SqlConnection.ClearPool` de la cadena anterior, para no reutilizar conexiones abiertas con la credencial vieja.
> 5. **`credencial-app --urgente`**, ante una sospecha de compromiso: `DENY CONNECT` y `KILL` sin espera. Acepta unos pocos errores 500 transitorios y lo informa en la salida.
> 6. **`GPOS.Migracion verificar` (S4)** informa toda sesión abierta de un `gpos_app_*` que no sea la generación vigente.
> 7. **Prueba PA-30:** dos rotaciones normales bajo carga sin ningún error 500, y ninguna sesión de la generación anterior al vencer el plazo.
>
> Las credenciales de lectura (`rotar-lectura`, [ADR-109](ADR-109.md)) no cambian. *Sustituye,* en T3-03 y PA-30 del diseño, «`DENY CONNECT` y `KILL`» y «sus sesiones cerradas» por lo anterior: en la rotación normal las sesiones de la generación anterior se cierran en 2 minutos como máximo, no en el acto; el cierre inmediato queda en `--urgente`. La intención firmada (que la generación anterior pierda el acceso) se cumple igual, sin errores visibles para el cajero en una rotación de rutina.
>
> **Riesgo aceptado:** la generación anterior conserva sus sesiones abiertas durante el plazo (2 minutos; hasta 6 si se sube). Ante un compromiso se usa `--urgente`.
>
> *Descartados:* mantener el `KILL` inmediato (un 500 posible bajo carga en cada rotación; PA-30 obligaría a reabrir en el comando) y solo `DENY CONNECT` sin `KILL` posterior (las sesiones de la generación anterior, incluidas las de un atacante, seguirían vivas sin límite; lo descartan el arquitecto y el auditor-seguridad).
>
> Costo: unos 0,2 dp del desarrollador de identidades (0,15 de la rotación y unos 0,05 de `ClearPool` y S4, inferido). **Decidido, no implementado.**
>
> \* *La hoja vive en el área común; no está copiada en `master`.*

> **Nota del registro (2026-10-15): la frase de DL-02 del punto 9 queda firme.** DL-02 (a) fue firmada por el propietario el 2026-10-15 con la misma respuesta. Queda sin efecto la salvedad en cursiva del punto 9 («Esta última frase viene de DL-02 […] pendiente de firma: si DL-02 no se firma, se retira»): en toda compilación Release, ningún modo sella ni crea cuentas al arrancar, y con una licencia vigente de anillo `Produccion` o `Beta` la API no arranca en Amplio. El detalle está en [ADR-83](ADR-083.md), punto 3. La condición de publicación que verifica que una instalación de cliente no lleve Amplio se propone como precisión de PUB-06 de [ADR-44](ADR-044.md) (M3; hoja de firma aparte, pendiente).
