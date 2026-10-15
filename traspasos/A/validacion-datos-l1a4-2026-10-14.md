# Validación del arquitecto: modelo de datos de L1a-4 (`datos-licencia-l1a4-2026-10-14.md`)

- **Fecha:** 2026-10-14. **Autor:** arquitecto-software, equipo A. Lo valido como dueño del blueprint (`blueprint-licencia-lote2-2026-10-14.md`, que con esto pasa a la **v2.3**).
- **Leído (solo lectura):** `datos-licencia-l1a4-2026-10-14.md`, secciones 0 a 6 y 11; `[LIC]` 4.1 y 4.1.2; ADR-59, punto 3; ADR-61, punto 5.
- **Etiquetas:** **[V]** verificado; **[I]** inferido.

| # | Punto | Dictamen | Motivo |
|---|---|---|---|
| 1 | Las llaves retiradas no excluyen una licencia de `Anteriores` (datos 4.2, regla 6) | **Confirmado con corrección (v2.3)** | Excluirla sería demasiado: la licencia dio derecho mientras su llave valía. Incluirla sin más también es un error: una licencia firmada con una llave retirada (quizá comprometida) daría como «fin de la gracia previa» todo su `vence` en la fórmula de NV-02, sin el tope de NV-08. Se aplica NV-08 dentro de la cadena (ver el texto exacto debajo de esta tabla). La consulta 4.2 no cambia: `Kids` y `RetirosConocidos` ya dan lo necesario |
| 2 | La bitácora no es fuente de `UltimaVerificacionUtc` (datos 2.6) | **Confirmado como diseño; precisión del texto firmado, pendiente de firma (DL-16)** | [LIC] 4.1.2 y ADR-59, punto 3, mencionan la bitácora entre las fuentes de las marcas. El razonamiento del arquitecto de datos es correcto: adelantar la marca exige el anillo en las otras dos fuentes, así que la bitácora no añade defensa. Con una cadencia menor, solo acortaría la gracia de 72 h sin que haya ataque. Además, la bitácora (DL-04) todavía no existe. Como se aparta de la letra del texto firmado, lo firma el propietario (DL-16). Hasta entonces, L1a-4 construye con dos fuentes (la fila y el archivo `estado`). Para las marcas de **inicio** de entorno y de retiro, la bitácora sigue siendo fuente |
| 3 | Esquema `dbo` y no `Licencia` (datos 1.2) | **Confirmado** | Es lo firmado en `[DAT]` 6.3 y lo que usan S1, S4 y PA-41. Un esquema nuevo solo ahorraría dos `DENY` y volvería ambiguo el prefijo de las claves `Licencia.*` de `Configuracion` |
| 4a | `AceptadaUtc` separada de `RecibidaUtc`, con la mínima por `sec` en `Anteriores` | **Confirmado** | La necesitan las reglas 4 y 5 de 6.1.1. Sin ella, una reinserción `RESTAURACION` rompería la cadena y la condición de NV-07. Las restricciones `CK_Licencias_Restauracion` y `AceptadaUtc ≤ RecibidaUtc` son correctas. El blueprint pasa a citar `Licencias.AceptadaUtc` (v2.3) |
| 4b | `Kid` pasa a `Kids` | **Confirmado** | Un archivo cofirmado tiene dos `kid`, y la regla 1 de esta validación lo necesita |
| 4c | `UX_Licencias_Aceptada` único sobre (`Sha256Contenido`, `NivelFirma`) con el filtro `Resultado = 'A'` | **Confirmado** | Es la forma que el blueprint 5.2 (v2.1) dejó al arquitecto de datos para SEG-L2-24. Evita migrar el índice de una tabla de solo inserción |
| 4d | `Licencia.SecMax` con el SHA-256 del contenido y los `Kids` | **Confirmado** | `ReglasAceptacion` lo exige (`ReglasAceptacion.cs:225`, citado [V] por datos). Es coherente con SEG-L2-18 |
| 4e | `Usuarios.SelloHabilitacion varbinary(512)` | **Confirmado, con una condición** | La estimación de unos 380 bytes es [I] y supone Data Protection. En Estricto, el sello usa el `CifradorAnillo` de H-17 v2 (blueprint 8), cuya sobrecarga todavía no está fijada. **Condición para SL:** una prueba que selle la cuenta más larga posible (código y sucursal de longitud máxima, SUPER con `FactorAlta`) con los dos cifradores y compruebe que cabe en 512 bytes |

**Texto exacto de la corrección del punto 1, que pasa a ser la regla 12 de la sección 6.1.1:**
- `LicenciaAceptada` agrega `DateTime? RetiroEfectivoUtc`:
  - null si al menos uno de sus `kid` no está retirado;
  - si todos lo están, L1a-4 lo calcula con `MotorEstados.GraciaLlaveRetirada` (NV-08: máx(publicación, conocimiento) + máx(72 h, `graciaDias` de la última licencia no retirada), redondeado al corte).
- Al calcular `r` (regla 4) con una anterior que tenga `RetiroEfectivoUtc`:
  - si `RetiroEfectivoUtc ≤ t`, la empresa **no tenía derecho**;
  - si no, `r.TopeGraciaUtc = mín(r.TopeGraciaUtc, RetiroEfectivoUtc, fin de vigencia de la entrada)`.
- Prueba mínima (corregida el 2026-10-14; rige la regla 12): (a) si la anterior está firmada solo con llaves cuyo retiro efectivo es anterior o igual a `t`, y la vigente omite la empresa, la empresa no tenía derecho: queda `NoLicenciada`, sin transición; (b) si el retiro efectivo es posterior a `t` (por ejemplo, el 9 de enero), `r.TopeGraciaUtc` queda limitado a esa fecha y la transición dura hasta `máx(9 de enero, SiguienteCorte(mín(t, emitida + 7 d) + máx(graciaDias, 72 h)))` (por ejemplo, el 17 de enero), nunca hasta el `vence` de la anterior.
- Costo [I]: ≈ 0,1 dp en L1a-3 y ≈ 0,05 dp en L1a-4.

**Otras observaciones (no bloquean):**
- La tabla de 2.4 del documento de datos (comentarios XML de `EstadosLicencia.cs`) es correcta.
- `Licencia.RegresosNivel` es una fila nueva respecto de `[DAT]` y es coherente con [PSF] 4A.6.

### Cierre
- Estado: Aprobado con observaciones.
  - Confirmados: 3, 4a, 4b, 4c y 4d.
  - Confirmado con una condición: 4e (prueba de tamaño en SL).
  - Confirmado con corrección: 1 (NV-08 dentro de la cadena, regla 12 del blueprint v2.3).
  - 2: confirmado como diseño, con la precisión DL-16 Pendiente de firma.
- Artefactos:
  - `C:\Users\lfmen\source\repos\Solucion GPOS NG\validacion-datos-l1a4-2026-10-14.md`;
  - `C:\Users\lfmen\source\repos\Solucion GPOS NG\blueprint-licencia-lote2-2026-10-14.md` (v2.3: registro de cambios v2.3, reglas 12 y 13 de 6.1.1 y DL-16 en 13.1).
- Supuestos: la sobrecarga del `CifradorAnillo` no está fijada todavía [I].
- Decisiones candidatas a ADR: DL-16, precisión de ADR-59, punto 3, y de [LIC] 4.1.2: fuentes de la última verificación correcta.
- Entregas a otros agentes:
  - **desarrollador-backend (L):** `RetiroEfectivoUtc` en L1a-3 (puede ir en el PR #31 o al empezar L1a-4) y su cálculo en L1a-4.
  - **desarrollador-backend (I):** la prueba de tamaño del sello en SL.
  - **arquitecto-datos:** citar la regla 12 en 4.2, regla 6.
  - **arquitecto-maestro:** DL-16 en la próxima hoja.
- Próximo paso recomendado: que L1a-4 empiece con este modelo y que la hoja recoja DL-15 y DL-16.
