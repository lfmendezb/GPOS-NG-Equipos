# Validación del arquitecto: PR #32 (L1a-2 «Reglas de aceptación»)

- **Fecha:** 2026-10-14. **Autor:** arquitecto-software, equipo A, como dueño del blueprint.
- **Qué revisé:** el PR #32, rama `a/lic-l1a-2` @ `a1562505`, en el árbol `GPOS-NG-lic`, solo en lectura (`git diff e59d8de2..HEAD`, 16 archivos). No compilé ni ejecuté las pruebas.
- **Contra qué lo contrasté:**
  - **[BP]** = `blueprint-licencia-lote2-2026-10-14.md` v2.3 (5.2, 6.1, 6.1.1 reglas 6, 12 y 13, 9.2 regla 5, 13.2);
  - **[PSF]** = `docs/arquitectura/2026-10-05-perfiles-seguridad-fips.md` v1.3, apartados 4A.2, 4A.4, 4A.5 y 4A.6;
  - `[LIC]` 3.2;
  - ADR-62.
- **Resultado:** el blueprint pasa a **v2.4**. Se agregan el registro de cambios v2.4, la sección 6.1.2 y una nota de alcance en 13.2.
- **Etiquetas:** [V] verificado; [I] inferido.

## 1. Dictamen por punto

| # | Interpretación del PR | Dictamen | Motivo y evidencia |
|---|---|---|---|
| 1 | Tocar `GPOS.Criptografia` con `VerificarCompacto` para `autNivel` | **Confirmado, con precisión** | `GPOS.Criptografia/Jws` es de L ([BP] 4.3). El `typ` propio separa los dominios: una licencia no puede pasar por una autorización ni al revés. Aplica las mismas reglas que la serialización general (`VerificadorJws.cs`, `VerificarCompacto` y `VerificarFirmas` [V]). **Precisiones:** se agrega a la interfaz de [BP] 6.1, y entra en el alcance de la revisión de código del auditor sobre `GPOS.Criptografia` (SEG-L2-08, [BP] 13.2) |
| 2 | Formato JSON de `ContenidoAutorizacionNivel` (`kid`, `desde`, `hasta`, `inicioRegreso`, `motivo`, `instalaciones`, `sec`; horas UTC) | **Confirmado en los nombres; corregir la lectura (corrección 1)** | Los nombres siguen [PSF] 4A.6, punto 1. El campo se llama `motivo`; su valor es la «causa» de catálogo cerrado que menciona [LIC] 3.2. Problema: la autorización se deserializa con `UnmappedMemberHandling.Skip` (`LectorContenidoLicencia.cs`, `Opciones` [V]). Un campo restrictivo que se agregue después sería **ignorado** por los binarios viejos: es la falla abierta que Q-17 quiso evitar con `instalaciones`. La autorización no tiene `crit` ni `fmt` |
| 3 | `aceptarHasta` rige desde las 00:00 de RD de ese día | **Confirmado** | Es una fecha civil. Coincide con la regla general de [BP] 6.1.2 (v2.4): las fechas civiles del formato se leen en hora de RD (`InicioDelDiaRd` [V]) |
| 4 | DL-14 con la fecha UTC de `emitida` | **Corregir (corrección 2)** | `vence` es una fecha civil de RD (el último día pagado) y `aceptarHasta` ya se lee en RD (punto 3). Para ser coherente, la fecha de `emitida` también se toma en RD: es igual o un día anterior a la fecha UTC, así que va del lado restrictivo. La diferencia es de un día como máximo y no tiene efecto de seguridad. Lo que importa es que el emisor use el mismo criterio. Se aplica también al tope «`hasta` + 31 días» de la autorización (`AutorizacionRegresoNivel.cs:104` [V]) |
| 5 | Piso de nivel monótono (un archivo Avanzado con `nivelMin` básico no baja el piso); `perfilMin` sí lo baja un archivo Avanzado | **Confirmado** | [PSF] 4A.4: `nivelMin` «solo **eleva**», mientras que `perfilMin` «solo lo baja o lo quita un archivo con firma Avanzada propia». Es asimétrico a propósito (`ReglasAceptacion.cs`, paso 10 [V]). La ausencia de `perfilMin` en un archivo Avanzado equivale a quitarlo, y el emisor lo arrastra con confirmación ([PSF] 4A.5, paso 3) |
| 6 | INV-1 y el `hasta` de la autorización contra máx(hora de referencia, `emitida` del candidato); el `desde`, contra la referencia | **Confirmado** | Usar la `emitida` del candidato **solo endurece** la comprobación: adelanta la caducidad y el fin de la ventana. Un candidato firmado con una llave básica no puede alargar nada con ella. El `desde` se compara con la hora protegida: con el reloj atrasado, el archivo se rechaza, que es la falla cerrada |
| 7 | Cadena de autorizaciones: rechazo de una `sec` anterior y de la misma `sec` con un `hasta` mayor | **Confirmado; ampliar la segunda regla (corrección 3)** | Rechazar una `sec` anterior es **necesario**: si no, una autorización vieja y más larga desharía un cierre anticipado ([PSF] 4A.6, punto 6). Para la misma `sec`, el PR solo rechaza un `hasta` mayor; un `hasta` menor u otro campo distinto pasan (`:120` [V]). Una misma `sec` con otro contenido es un error del emisor, como en la licencia ([LIC] 3.1.1, punto 7) |
| 8 | La recarga idempotente no vuelve a evaluar la caducidad ni los retiros | **Confirmado** | [PSF] 4A.2, punto 4, e INV-7: la caducidad solo rige al aceptar. El retiro posterior ya surte efecto por INV-8 (la gracia `LlaveRetirada` del motor). L1a-4 no inserta fila en una recarga (datos L1a-4, 4.1) |
| 9a | Una firma latente sin `autNivel` se ignora si otra firma cuenta | **Confirmado** | «Obligatorio en todo archivo firmado con un `kid` latente» ([PSF] 4A.4) se lee como «necesario para que esa firma cuente». El archivo vale por la otra firma, igual que si viniera sin la latente. Rechazarlo no agrega seguridad |
| 9b | `InstalacionId` comparado sin distinguir mayúsculas | **Confirmado, con precisión** | Es seguro si el formato no distingue mayúsculas. **Precisión ([BP] 6.1.2):** el `InstalacionId` es un GUID en formato `D` en minúsculas (128 bits aleatorios, C-08), y L1a-4 lo genera así |
| 9c | Se acepta una licencia sin empresas | **Confirmado** | Está firmada por GSF y no da nada: todas las empresas quedan `NoLicenciada`, con la transición de NV-02 si tenían derecho. Sirve para retirar todo lo de una instalación sin corte inmediato |

**Contraste con [BP] v2.3:**
- **Regla 6 de 6.1.1:** se cumple. Los códigos de empresa repetidos sin distinguir mayúsculas se rechazan y el RNC lleva 9 u 11 dígitos ASCII (`LectorContenidoLicencia.Validar` [V]).
- **Reglas 12 y 13:** no son de esta pieza. `KidsFirma` alimenta la columna `Kids` (datos de L1a-4).
- **SEG-L2-24:** el enganche está en el paso 4, con la prueba omitida. Es lo previsto en 5.2: va con la versión de las llaves Avanzadas.
- **DL-14:** está aislada en un solo commit que se puede revertir, con la corrección 2.

## 2. Correcciones necesarias en el código (lista única)

1. **Autorización estricta ante campos desconocidos (Media).**
   - `LeerAutorizacion` rechaza todo miembro que no sea `kid`, `desde`, `hasta`, `inicioRegreso`, `motivo`, `instalaciones` o `sec`, con 422 `LICENCIA_AUTORIZACION_INVALIDA`. Se usan unas opciones con `UnmappedMemberHandling = Disallow` o una comprobación explícita de los nombres.
   - Prueba: una autorización válida con un campo extra (por ejemplo, `"x": 1`) se rechaza.
   - Así, cualquier campo que se agregue en el futuro exige binarios nuevos y falla cerrado.
2. **Fechas civiles en hora de RD (Baja).**
   - `ReglaVigenciaBasica.VenceMaximo` = `DateOnly.FromDateTime(emitidaUtc − 4 h).AddDays(200)`.
   - En `AutorizacionRegresoNivel`, `venceMaximo` = `DateOnly.FromDateTime(a.Hasta − 4 h).AddDays(31)`.
   - Se reutiliza el desfase de RD (el de `HoraEmpresa` o `DesfaseRd`).
   - Pruebas en el borde: `emitida` = 02:00 UTC.
   - El emisor (EM) usa el mismo criterio.
3. **La misma `sec` de autorización tiene que traer el mismo contenido (Baja).**
   - Si `a.Sec == p.SecMaxima`, la autorización se rechaza salvo que `desde`, `hasta`, `inicioRegreso` y `kid` sean iguales a los ya vistos. `EstadoRegresoKid` guarda el `desde` y el `hasta` de la autorización de mayor `sec`.
   - Si no se quiere ampliar `EstadoRegresoKid`, basta con exigir `a.Hasta == p.HastaVigente` y `a.InicioRegreso == p.InicioRegreso`.
4. **Comentario (Baja).** En `SituacionInstalacion`, el `<param>` de `SecMaximaEfectiva` dice `LicenciaSecMax`; la clave es `Licencia.SecMax` (datos de L1a-4, 2.4).

Ninguna corrección cambia las firmas públicas, salvo la variante opcional de la 3.

**Costo [I]:** unos 0,15 dp en L1a-2 y 0,05 dp en EM.

### Cierre
- Estado: Aprobado con observaciones.
  - Confirmados: 1, 3, 5, 6, 8 y 9 (1 y 9b con precisión).
  - Confirmado en los nombres, con corrección en la lectura: 2.
  - Corregido: 4.
  - Confirmado y ampliado: 7.
  - Conviene aplicar las correcciones 1 a 3 antes de unir. La corrección 1 cierra una falla abierta futura en el formato que comparte EM.
- Artefactos:
  - `C:\Users\lfmen\source\repos\Solucion GPOS NG\validacion-l1a-2-reglas-aceptacion-2026-10-14.md`;
  - `C:\Users\lfmen\source\repos\Solucion GPOS NG\blueprint-licencia-lote2-2026-10-14.md` (v2.4).
- Supuestos:
  - El código leído es `a1562505`, sin compilar ni ejecutar.
  - Todavía no existe ningún `InstalacionId` generado en otro formato.
- Decisiones candidatas a ADR: ninguna. Son precisiones de [PSF] 4A.6 y de DL-14, que sigue pendiente.
- Entregas a otros agentes:
  - **desarrollador-backend (L):** correcciones 1 a 4; el `InstalacionId` en formato GUID `D` en minúsculas en L1a-4.
  - **desarrollador-backend (I), para EM:** el formato estricto de la autorización y las fechas civiles en RD (DL-14 y `hasta` + 31).
  - **auditor-seguridad:** incluir `VerificarCompacto` en la revisión de `GPOS.Criptografia`.
- Próximo paso recomendado: que L aplique las correcciones 1 a 3 en `a/lic-l1a-2` y B valide de nuevo antes de unir.
