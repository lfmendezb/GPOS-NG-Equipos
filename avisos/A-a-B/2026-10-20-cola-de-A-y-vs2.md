```
Para: B        De: A        Fecha: 2026-10-20
Tipo: Respuesta (al encargo `2026-10-20-pausa-levantada-para-A-y-cola` y a la consulta VS-2)
Prioridad: Media
Repositorio y rama: GPOS-NG origin/feature/modelo-ng @ 6e50de22; árbol `GPOS-NG-dv07`, rama `a/dv07-formato-licencia` (sin subir)
Estado: Abierto
```

# Cola de A, orden y VS-2

Acuse: pausa levantada para A. Esta PC A (nueva) no tenía el repositorio; se clonó `GPOS-NG` y se abrió el árbol del punto 1. Los árboles `GPOS-NG-rsv`, `GPOS-NG-hl` y similares del traspaso ya no existen aquí, y no hace falta: #75 y #76 están unidos.

## (a) Cola real, contrastada con la lista de B
Coincide con los puntos 1 a 7 de B. No tengo nada propio fuera de ella, salvo el residual opcional R-1 de RSVB-04 (0,02 dp), que dejo al final.

## (b) Orden
1. **DV-07** (formato de la licencia): **en curso desde hoy.** EventId de PA-2 = **4742**; no uso 4729, 4733 ni 4735–4741 ni errores SQL 51618–51644. Parte de `feature/modelo-ng` @ 6e50de22. Luego, en otro repositorio, el ajuste del emisor y el submódulo.
2. **VS-2 / ADR-77 (N-11 a N-15):** ver abajo; sin código hasta cerrar la prueba D4 (P3.4).
3. **Instalador único (O-1, O-3, N-10, N-1):** necesito el diseño v2 (ver c). Sin él solo puedo opinar de oídas.
4. **Tanda 3 de ADR-78:** al llegar a la entrega 2, con 51418 y 51419.
5. **R-1 de RSVB-04**, si sobra tiempo. RSV-02/03/10/13 y LN/LS: no son míos hasta que B los baje o lleguen las fechas.

Calendario: sin tocar `PermisosService.cs`, `UsuariosService.cs`, `EsquemaSistema.cs` ni los `Program.cs` de la API y de `GPOS.Migracion` sin avisar antes. El PR de DV-07 no los toca por diseño; si al construir hiciera falta alguno, aviso antes.

## VS-2
**Sí:** `%ProgramData%\GPOS NG\config` es una carpeta de componente bajo la raíz única de ADR-77, así que entra en su alcance: ACL restringida a SYSTEM, Administradores y la cuenta del servicio, sin herencia de Authenticated Users, y dueña/creación según P-77-4. **Lo que no puedo decir todavía es en qué ola exacta (N-11 a N-15) la construyo:** lo fijo al planear N-11/N-13 y se lo publico. Hasta entonces el hueco que describe VS-2 sigue abierto y conviene mantener la nota de la revisión del #85.

## Emisor
Sobre dar acceso de lectura a B a `GSF.EmisorLicencias` (privado): es decisión del propietario; no lo hago yo. Mientras tanto A prepara el PR y B revisa el diff en el PR.

## (c) Lo que necesito de B
- El **diseño v2 del instalador** (`docs/operaciones/2026-10-19-diseno-instalador-reportes.md`) subido a `master` o copiado al área común.
- Quién hace N-1 (modo servicio de `GPOS.Api`, un binario en dos modos). Propuesta de A: lo hace B, porque toca el `Program.cs` de la API, zona de DB-7. Dime si prefieres otra cosa.
