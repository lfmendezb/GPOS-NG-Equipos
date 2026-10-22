Para: C        De: B        Fecha: 2026-10-22
Tipo: Encargo (tareas nuevas, aprobado por el propietario)
Prioridad: Media
Repositorio y rama: GPOS-NG (según la tarea); área común `traspasos/C/`
Estado: Abierto

# Tareas nuevas para C

El propietario aprobó este encargo en el chat (2026-10-22: «Si, aprobado»). Todo es lectura, planes y pruebas dirigidas, sin suite completa ni compilaciones largas (OSHIN-LEGION). Lo que ya tienes con fecha va primero (PR de limpieza de `ClearAllPools()`; rebase del #156 e integración de los 6 commits de captura de `b/dorados-captura`).

## Revisiones de pruebas (3 días hábiles desde el aviso de cada rama)
1. **#168 (E-1)**: contra tu plan de S-16 v2 y las 20 mutaciones que reportó el agente de B. Documenta los 3 fallos preexistentes de `feature/modelo-ng`: `ReportesTests.Filtra_antes_de_agrupar_y_totaliza`, `ReportesTests.Exporta_a_los_seis_formatos_conservando_tipos` y `SucursalOrigenTests.Ventas_por_sucursal_y_campos_elegidos_por_el_usuario`.
2. **#170 (T4-03a)**: sus 73 casos de `ChromiumAisladoTests` contra tu plan de laboratorio (TL-01 a TL-03, L-1 a L-4); B corrige M-170-2 y te avisa.
3. **#175 (T4-04)**: contra tu plan de T4-04 y T4-06 v2.

## Planes y casos nuevos
4. **M-168-2** (403 al ADMIN que toque la bandera; hoja del #177) y **M-168-1** (regla única del SUPER): plan de pruebas.
5. **S152-02** (C-02-1 a C-02-5 de A) y **T4-03b**: plan de pruebas.
6. **T4-10 y T4-11** (vistas `imp`, PR #178): plan con S-01 a S-09 y las pruebas negativas de autorización del lector único.
7. **T1-b (MSI de la API) y spike del modo Amplio**: casos de laboratorio (DE-01, DE-10 a DE-16; guía de A en `traspasos/A/guia-t1b-msi-api-2026-10-22.md`, #165 y #173).

## Corrección de pruebas
8. Las 4 pruebas de `ComprobacionCarpetasPreviasTests` (#124) fallan en la PC de B por un ACE de `LFMB\CodexSandboxUsers` en `%TEMP%`. A decide si la precondición `TemporalDelUsuario` omite o falla (tu aviso `A-a-B`); tú revisas el cambio.

No incluyo D-25 ni D-26 (esperan a A) ni la tanda de dorados nueva.

Respuesta requerida: acuse con fechas.
