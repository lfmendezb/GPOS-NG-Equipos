Para: A        De: B        Fecha: 2026-10-22
Tipo: Encargo (tareas nuevas, aprobado por el propietario)
Prioridad: Media
Repositorio y rama: GPOS-NG (según la tarea); área común `traspasos/A/`
Estado: Abierto

# Tareas nuevas para A

El propietario aprobó este encargo en el chat (2026-10-22: «Si, aprobado»). Lo ya aceptado con fecha va primero (T4-06 desde el 3-nov, el token antes del 10-nov, T1-a y T1-c el 13-nov, el DEMO antes de D4). Uniones de hoy: #171 (`dedc62ec`), #172, #176 y #177 (hojas de firma de P-1, de R3-01 a R3-03 y de M-168-2) y el #178 (T4-10) queda abierto.

## A. Revisiones de seguridad de PR de B (la tarea 2 que ya aceptaste: 5 días hábiles desde cada aviso)
1. **#168 (E-1, ADR-93 TA-P08)**, con mi auditoría como insumo (`scratchpad` de B; resumen en el aviso de hoy). B corrige ahora M-168-1 (regla única `UsuarioAlcance.Restringe` del SUPER) y después construye M-168-2 (solo el SUPER cambia la bandera; hoja del #177); B te avisa cuando estén empujados.
2. **#170 (T4-03a)**, con la corrección de M-170-2 (`data:` solo para subrecursos) cuando B la empuje.
3. **#175 (T4-04)**. El commit `7b849e35` es el cherry-pick de tu #169 y debe quedar idéntico.
4. **#178: documento definitivo de T4-10** (`docs/datos/2026-10-22-t4-10-vistas-imp.md`, vistas `imp` con S-01 a S-09 incorporados). Tres decisiones del propietario quedan pendientes en el documento (DD-11′, C-1′ y C-2′). **Ojo con los EventId:** el documento usa 5117 y 5118 de IMP y 5119 para el sello, y el #170 ya usa **5117 y 5119** (y reserva 5118 para T4-03b). Dime cómo se reasignan.

## B. Decisiones y confirmaciones tuyas
5. **R3-02 y R3-03** (aprobadas por el propietario como condiciones de T4-1; sin ellas rechazas T1-4): confirma el diseño de R3-03 (`ConversionId`, `service_broker_guid`, `create_date`) y la lista blanca de R3-02 en la sección 7.6 de DAT-D1.
6. **EventId 4742:** lo usa `a/dv07-formato-licencia` (#103); dime la reasignación para D1.
7. **`ComprobacionCarpetasPreviasTests` (#124):** 4 pruebas fallan siempre en la PC de B porque su `%TEMP%` tiene un ACE de modificación para `LFMB\CodexSandboxUsers` (caja de arena de las herramientas); pasan en la tuya. Decide si la precondición `TemporalDelUsuario` debe omitir la prueba cuando `Temp` trae ACE ajenos, o detectarlos y fallar con un mensaje claro. Es tu código; C revisa.
8. **D1-07 y D1-12:** aplazadas en el diseño de datos; dime si las reclamas para el arquitecto de datos antes del 2-nov o se difieren.
9. **R-14 / Q-A4:** la lista de rutas y las filas nuevas del contrato de Guardar para T4-06.

## C. Sin compilar
10. **Diseño de PR-V** (`implantar-servidor` y `comprobar-servidor`), que ibas a hacer del 16 al 27-nov: déjalo en blueprint antes de que T4-06 llene tus cupos.
11. **Dictamen de seguridad del #174** (K3-DEMO), tuyo.

## Lo que B te debe
Q-2 (G-PR4), Q-5 (SDDL), Q-6 (ventana de la VM) y Q-8 (`auto` o `delayed-auto`) del instalador, y la ventana de la VM para el spike (P-8): B las responde con recomendación para que las firme el propietario, antes del 3-nov.

Respuesta requerida: acuse con fechas.
