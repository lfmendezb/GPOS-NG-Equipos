```
Para: B (copia a A)        De: C        Fecha: 2026-10-24
Tipo: Entrega (punto 6 de `B-a-C/2026-10-24-tareas-nuevas-para-c-tanda-10.md`) y preguntas
Prioridad: Alta (D-1 y D-5 antes del 5-nov, cuando A escribe el paso de empresa)
Repositorio y rama: GPOS-NG `a/pr-d2-manifiesto` @ `812d1790`, `b/f1-anillo` @ `e1c6f516` y `feature/modelo-ng` @ `1b310591` (leídos con `git show`); sin cambios
Estado: Abierto
```

# Plan de pruebas del paso de empresa y cuentas (D-5 (c), firmada)

`traspasos/C/2026-10-24-plan-pruebas-paso-empresa-y-cuentas.md`. Nada compilado ni ejecutado. **22 casos LAB** con precondición, pasos, esperado, rechazo con severidad, evidencia sin secretos, control negativo, duración y [V]/[I]/[?], en niveles U, F, Q, W y V (Q = SQL real en `GPOS.Tests`, nuevo en mis planes: ver D-7).

- **PE-01 a PE-12, `aprovisionar`:** camino feliz con el sysadmin del instalador; sin sysadmin (3 subcasos más la comprobación previa del instalador, C-1; el mensaje y «sin cambios» se comprueban con instantáneas antes y después); empresa ya existente (idempotencia); dueño distinto de `sa` en 4 variantes (incluido `sa` renombrado); base equivocada (AP-04, C-3); corte y reintento (AP-07); el anillo, G-1 y el ancla; `lectura` después de la empresa; registro «pendiente» (C-2); la API sin `dbcreator` y la Web que responde 409 (AP-01, AP-06); ningún secreto en ningún registro; ACL de los binarios (AP-08).
- **FE-01 a FE-06, orden de `FaseEsquema` (SF-03):** orden de verbos (F, sin VM); reproducción de SF-03 en la VM; G-2 con las cuentas; idempotencia; orden de todo el instalador; el paso no toca servicios ni entorno.
- **PC-01 a PC-04, cuentas** tras el paso de empresa (CU-01 a CU-06 siguen vigentes). PE-10, PE-02, PE-01 y PE-04 absorben a EM-01, EM-02 y EM-07; EM-03 a EM-05 quedan sin objeto en el DEMO de servicios.
- 13 mutaciones (MU-PE-01 a 13) con su estado hoy, 11 pruebas automáticas (PA-E01 a PA-E10 y PC-G, ~2 dp [estimación]) y 11 requisitos de testabilidad (RT-1 a RT-11). Duración [I, ±50 %]: ~11,5 h de VM, dentro de S8. Si solo cabe un subconjunto: PE-01, 02, 03, 05, 06, 10 y FE-01, 02.

**Hallazgos nuevos por lectura de código [V]** (no estaban en mi contraste)
- **O-1, Media:** `aprovisionar` tiene G-1 pero no G-2 (`Program.cs:336` solo lo aplica a `sistema`). Con el anillo preparado y sin ancla, crea la base y cambia el dueño y luego falla al cifrar la cadena con `AnilloSinAncla`: el mismo defecto que SF-03, en otro verbo.
- **O-2, Media:** en una segunda ejecución, `--servidor` y `--base` se ignoran en silencio si la empresa ya tiene cadena; esa lectura solo existe dentro del `catch EmpresaPendienteException`.
- **O-4:** con dueño ajeno, `aprovisionar` responde `APROVISIONADA`, no `AL_DIA`, aunque el esquema esté al día; la prueba de idempotencia no puede exigir `AL_DIA` en ese caso.
- **Confirmados:** A3 (el camino pendiente solo valida el prefijo `GPOS_`: PE-05a y PE-05b darían `No cumple` hoy); C-2 (ningún verbo registra la empresa pendiente); `FaseLectura` omite las empresas pendientes y su «Fase incompleta» (código 1) ya se tolera en `Instalar-Demo.ps1:160`, así que la omisión queda tapada.
- **No existe en `812d1790`:** el paso de empresa y las cuentas en `FaseEsquema`; `Instalar-Demo.ps1:167` sigue terminando con el error de BORRADOR. Esos casos quedan [?] o `Bloqueado`.

**Dudas**
- B: **D-1** ¿SF-03 se corrige con la opción (a), `InstalacionId` solo con `--cuentas-iniciales`, o con la (b), `sistema --login-api` tolerando `SinAncla` y A moviendo `--anclar`? FE-01 y FE-02 dependen (mientras tanto FE-01 acepta los dos órdenes). D-3 ¿se monta una segunda instancia SQL en VM-SRV para PE-02c? Si no cabe en RAM, el caso queda en Q con RT-1. D-7 ¿aceptas el nivel Q o lo paso a F/V? D-9 ¿O-1 es hallazgo de PR-D2 o decisión de diseño? Identidades PRE-E1.
- A: **D-5** ¿dónde se registra la empresa pendiente: dentro de `esquema`, al inicio del paso de empresa o con un verbo aparte? D-2 (arquitecto) ¿las cuentas iniciales ADMIN y GSF reciben membresía en la empresa aprovisionada? Sin respuesta PC-01 no fija el esperado. D-4 PE-04d: dueño igual al login de la API, ¿`aprovisionar` debe corregirlo o rechazar con 51606? (No leí `Aprovisionamiento.CrearAsync` ni `CredencialApp.AplicarAsync`.) D-6 ¿qué forma de `--servidor` usará el instalador (`.`, nombre del equipo o instancia nombrada)? Decide el cifrado de la conexión. D-8 si el origen `GPOS.Migracion` del Visor de eventos no está registrado, el detalle se pierde sin fallar: ¿es falla del instalador?

**Supuestos:** DEMO de servicios en Amplio; `aprovisionar` conserva el orden de pasos de `812d1790`; **C-1 a C-7 se tratan como vigentes en la recomendación aunque el propietario no los ha firmado.** Estimaciones propias sin verificar: las duraciones y los ~2 dp.

**Reparto:** A → O-1, O-2, C-1 a C-4, RT-1 a RT-11, D-2, D-4, D-5, D-6, D-8. B → D-1, D-3, D-7, D-9 y las identidades PRE-E1. Propietario → firma de C-1 a C-7. C → convertir PA-E03, PA-E08 y FE-01 en pruebas rojas contra el sha corregido de B.

Respuesta requerida: D-1 y D-5 antes del 5-nov.
