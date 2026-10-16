# Diseño UX/UI: ventana «Facturación Corporativa» y administración del beneficio

[Diseño UX/UI] · Diseñador UX/UI (equipo A) · 2026-10-15 · **Estado: Completado (diseño para la entrega 3; las preguntas UQ-1 a UQ-9 están Pendientes de firma)** · Sin commit · No toqué código.

**Fuente de verdad:** `traspasos/A/hoja-firma-vertical-corporativa-2026-10-15.md` (**[HF]**), firmada el 2026-10-15: H-01 a H-03 y H-05 a H-11 en (a), F-1 a F-4, PF-1, PF-3 y PF-4. **H-04 sigue abierta.** Se suma **F-5**, que agregó el propietario: «En la pantalla al cajero debe presentarle cuanto le resta del consumo del subsidio por empleado. Y en el ticket de impresión también debe indicar cuanto le resta después de cada consumo.»
**Insumos:**
- **[POS]** `traspasos/A/pos-vertical-corporativa-2026-10-15.md`, revisión 2. Donde choca con [HF], manda [HF]: ya no hay beneficio «C» aparte (F-2), el artículo fuera de franja se bloquea (F-1 deja sin efecto B-6 y E-7) y la tolerancia de la franja es de 0 minutos (PF-1 deja sin efecto los 5 minutos de R-H5).
- **[DAT]** `traspasos/A/datos-vertical-corporativa-2026-10-15.md`, con FD-01 a FD-15 pendientes de firma.
- **[SW]** `traspasos/A/blueprint-vertical-corporativa-2026-10-15.md`, del arquitecto de software. **Todavía no existía** cuando cerré este documento (lo revisé dos veces, la última justo antes de cerrar). Los puntos de contacto están en la sección 9.
**Base visual y componentes:**
- **[NG]** `GPOS NG`, rama `origin/feature/modelo-ng` en `ce33b2a8`.
- **[UXV]** `origin/b/verticales-diseno:docs/ux/` (diseños de B): `2026-10-07-ventanas-verticales.md`, `2026-10-08-ventana-facturacion-duty-free.md` (**[DF]**), `2026-10-08-ventana-facturacion-restaurante.md` (**[RM]**) y `2026-10-08-ventana-facturacion-estandar.md`.

**Convención:** *verificado* significa leído en esta sesión, con `ruta:línea`; *inferido* es una estimación sin medir. Los tiempos son metas para medir en el piloto.

**Prefijos de este documento** (para no chocar con los CO-01 a CO-04 de la hoja de catering ni con los FD-nn de [DAT] y [DF]):
- **VC-nn**: pantallas de la caja.
- **AC-nn**: pantallas de administración.
- **EC-nn**: estados.
- **TK-nn**: tickets impresos.
- **UQ-n**: preguntas.

---

## 0. Lo que existe y se reutiliza (verificado)

| # | Hecho | Evidencia | Efecto en el diseño |
|---|---|---|---|
| X-1 | La Facturación Ágil tiene una cabecera `h5` con chips (caja, turno, jornada cerrada o sin apertura) y los botones a la derecha | `src/GPOS.Web/Components/Pages/Ventas/PuntoVenta.razor:25-55` | Se usa la misma disposición en VC-01, con chips propios |
| X-2 | La rejilla es 8/4. El panel del total usa `.pos-total` (degradado del primario), con `Typo.h3`, la clase `sensible` y los números tabulares | `PuntoVenta.razor:152-167`; `src/GPOS.Web/wwwroot/app.css:29-30`, `:71-73` | El panel del total y del reparto usa el mismo estilo. Los montos llevan `sensible`, de modo que el botón del ojo los desenfoca (`app.css:215-218`) |
| X-3 | Paleta: primario `#1f3a93`, secundario `#3fa34d`, fondo `#f6f7fb` y texto de advertencia `#0b1f44` | `src/GPOS.Web/Components/Layout/MainLayout.razor:132-138` | Es la misma paleta. No hay colores nuevos salvo los tres del reparto (5.3) |
| X-4 | El editor de líneas agrega con Enter, busca con F3, acepta «3+código» y devuelve el foco con `EnfocarAsync` | `src/GPOS.Web/Components/Compartidos/EditorLineas.razor:26`, `:244-277` | Se reutiliza el patrón del campo de código. La lista de líneas es propia, porque lleva el reparto |
| X-5 | El diálogo de autorización de supervisor pide usuario, contraseña y motivo, o solo el motivo si el usuario tiene el privilegio | `src/GPOS.Web/Components/Compartidos/DialogoAutorizacionSupervisor.razor:1-30` | Se usa para el reverso y la identificación sin carné. **Hay que ocultar «Autorizo yo»**, porque esas operaciones exigen otra persona (ADR-68, [HF] H-08) |
| X-6 | Reimpresión: la primera impresión es libre; las siguientes llevan «COPIA n». **Los documentos sin NCF se imprimen libres y no se cuentan** (`Impresiones = 0`) | `src/GPOS.Core/Servicios/Nucleo/ReglasReimpresion.cs:17-41`; `src/GPOS.Contracts/Impresion/Reimpresion.cs:15-19`; `ModeloImpresion.cs:55-60` | El ticket interno no tiene NCF, así que hoy se reimprimiría sin contarse. **Propongo que se cuente** (UQ-3 y la sección 9) |
| X-7 | Papel de 80 mm y de 58 mm. La plantilla de rollo es HTML (Razor), con 8 pt en 80 mm y 7 pt en 58 mm | `src/GPOS.Contracts/Impresion/ModeloImpresion.cs:198-199`; `PlantillasRazor.Rollo.cs:13-30` | Los tickets TK-01 a TK-04 son plantillas de rollo nuevas. Las maquetas de la sección 4 usan unas 42 columnas en 80 mm y 32 en 58 mm (inferido para 8 y 7 pt) |
| X-8 | `GPOS.Componentes` **todavía no existe**: se crea en la entrega 3, y los componentes nuevos de las verticales se escriben allí, sin tocar `PuntoVenta.razor` | `docs/adr/ADR-004.md:21-23` (precisiones V-3 y DY-14) | Todo componente nuevo de este documento va en `GPOS.Componentes` |
| X-9 | B ya diseñó `PanelCobroPos`, `RejillaCobro`, `BotoneraCapas`, `EsperaFirma`, `ChipEstadoConexion`, `BandaVigencia` y `DialogoFaltantes` | [RM] 5.2 (líneas 682-692); [DF] 5.2 | Se reutilizan. La botonera de la cafetería es `BotoneraCapas` con datos de `corp`, sin depender de `res` |

**Lo que no se copia de la Facturación Ágil:** los datos del cliente plegados, el selector de comprobante, el «Pago múltiple» y «No generar comprobante» (`PuntoVenta.razor:64-135`). En el consumo de un comensal no hay comprobante que elegir, y **«No generar comprobante» no existe en esta ventana**: ni en un selector, ni en un mensaje, ni en una ayuda ([HF] H-03 (b), descartada).

---

## 1. Objetivo y usuarios

**Objetivo:** que el cajero del tercero identifique sin error al comensal y despache su consumo en **10 a 12 s** cuando la empresa lo cubre todo, con un pico de **unas 150 comidas por franja y por caja**. El comensal sabe en todo momento cuánto le queda de su bolsa (F-5).

| Usuario | Dispositivo | Lo que más le importa |
|---|---|---|
| **Cajero de cafetería** (del tercero) | PC de caja de 1366 × 768 o más, con teclado, un lector de carné que emula un teclado y, a veces, pantalla táctil. También una tableta con MAUI | Velocidad, no equivocarse de persona, y que el sistema le diga qué cubre la empresa sin tener que calcularlo |
| **Supervisor de cafetería** (del tercero) | La misma caja o la suya | Autorizar reversos e identificaciones sin carné, y cerrar la caja |
| **Comensal** | Ninguno (mira el ticket) | Cuánto pagó, cuánto le queda de la bolsa y si ya tomó el almuerzo |
| **Visitante** | Ninguno | Su comprobante (E32 o E31) |
| **Administrador del beneficio** (RR. HH. de la **empresa**) | PC de oficina | Padrón, carnés, fotos, montos, franjas, coberturas y corte de nómina, sin errores masivos |

**El tercero nunca ve las pantallas de administración** (H-09 (a), CA-09): no aparecen en su menú y la API le responde 403.

### 1.1 Presupuesto de tiempo (metas inferidas, se miden en el piloto)

| Paso | Acción | Meta | Sistema (para [SW]) |
|---|---|---|---|
| 1 | El comensal acerca el carné | 1 s | De la lectura a la foto: ≤ 1 s p95 ([POS] 1) |
| 2 | El cajero compara la foto y pulsa **Enter** | 2 a 3 s | — |
| 3 | Tres artículos (tres toques en la botonera o tres lecturas) | 3 a 4 s | Cada cotización ≤ 300 ms en la LAN; **nunca bloquea el toque siguiente** |
| 4 | **Ctrl+Enter** (Despachar), si «A pagar» es 0 | 1 s | Emisión ≤ 1,5 s p95 |
| 5 | Ticket | 2 s, en paralelo | La impresión no bloquea la lectura del siguiente carné |
| | **Consumo sin dinero** | **9 a 11 s** | |
| 6 | Con dinero: efectivo exacto o nómina (Enter en la fila) | +3 a 4 s | — |
| 6′ | Con tarjeta (pinpad) | +10 a 15 s | — |

**Promedio ponderado** (inferido: 70 % de los consumos sin dinero, 25 % con efectivo o nómina y 5 % con tarjeta): unos 11 s, es decir, unos **5,4 comensales por minuto por caja**. Con 300 comensales y la mitad en 30 minutos llegan 5 por minuto: **una caja va al límite; se recomiendan dos** ([POS] 1).

---

## 2. Flujos de interacción

### 2.1 Navegación y activación

- **Menú** (títulos con mayúsculas de título, RG-30), cada opción con su permiso y condicionada al módulo `CORPORATIVA`:

| Grupo existente | Opción | Permiso propuesto | Perfil |
|---|---|---|---|
| Punto de Ventas | **Facturación Corporativa** | `facturacion-corporativa` | Cajero y supervisor de cafetería |
| Punto de Ventas | **Consumos Internos** (consulta y reverso) | `consumos-internos` (ver); `reverso-consumo` (autorizar) | Supervisor; el cajero solo ve su jornada |
| Tablas › Corporativa | **Comensales**, **Categorías y Montos**, **Centros de Costo**, **Franjas y Composición**, **Artículos de Cafetería** | `comensales`, `beneficios-corporativa` | Administrador del beneficio |
| Ventas | **Corte de Nómina** | `corte-nomina` | Administrador del beneficio |
| Admin | **Parámetros de la Corporativa** | `beneficios-corporativa` (el modo fiscal, solo el SUPER) | Administrador del beneficio |
| Admin | **Digitación de Contingencia** | `contingencia-corporativa` | Administrador del beneficio (UQ-6) |

- **Una caja en modo «Corporativa»** abre la ventana VC-01 al entrar a Punto de Ventas (ADR-112, nivel 3). No ofrece la Facturación Ágil como alternativa.

### 2.2 Flujo principal del cajero (F-01 de [POS] con [HF])

```
 LISTA ──(lector de carné)──► LEYENDO (≤ 1 s) ──► POR CONFIRMAR ──Enter──► CONFIRMADO: AGREGANDO ──Ctrl+Enter──┬─ A pagar = 0 ─► EMITIENDO ─► RESULTADO ─┐
   ▲                               │                    │                         │                             └─ A pagar > 0 ─► COBRO ─Enter─► EMITIENDO ┘
   │                               │                    ├─ Alt+N «No es la persona» ─► bloqueo preventivo + bitácora ─► LISTA
   │                               │                    └─ Esc «No atender» ─────────────────────────────────────────► LISTA
   │                               └─ carné desconocido, bloqueado, inactivo… (EC-01 a EC-04) ─► alerta ─► LISTA o visitante (F4)
   └──────────── siguiente lectura de carné o Enter en RESULTADO (la foto ya se borró al emitir) ◄──────────────────────────────────────────────┘
```

| Paso | Qué hace el cajero | Qué hace la ventana | Regla |
|---|---|---|---|
| 1. **Leer el carné** | Nada: el comensal acerca el carné | Detecta la lectura por el prefijo del lector (6.3), **en cualquier campo que tenga el foco**, y pide la tarjeta del comensal | El carné solo lleva un identificador opaco. Los datos y la foto vienen del servidor (H-08 (a)) |
| 2. **Panel del comensal** | Mira la foto | Muestra la **foto grande** (240 × 320 o más), el nombre, el código, la categoría, el **saldo de la bolsa**, el **estado del almuerzo y de la cena** de hoy, el **cupo de nómina** si aplica y los avisos | F-5: el saldo aparece desde la lectura |
| 3. **Confirmar la identidad** | **Enter**, o toca [✓ Es la persona] | Habilita la botonera y el código, reduce la foto a una miniatura y pone el foco en el código | **Nada se agrega antes de confirmar** (CA-01). Una lectura de artículo antes de confirmar se rechaza con un sonido y el aviso «Primero confirme la identidad.» |
| 4. **Botonera por franja** | Toca botones o lee códigos | Muestra la franja vigente con los grupos de la composición y su avance («Plato fuerte 1/1 ✓»). Los artículos de otras franjas aparecen en gris, con candado y su horario | F-1 y PF-1: el servidor valida la franja **al agregar cada línea**, con su hora y tolerancia 0 |
| 5. **Reparto por línea y saldo en vivo** | Mira | Cada línea muestra sus fichas: **Almuerzo 100 %**, **Bolsa RD$ x** y **Paga RD$ y**. El panel derecho muestra «Bolsa: RD$ 1,000.00 → **queda RD$ 840.00**» y lo actualiza con cada línea | Lo calcula el servidor con el orden fijo de [HF] 3.5. **Agregar una línea puede cambiar el reparto de las anteriores** (la bolsa paga de mayor a menor importe): la ventana marca las líneas que cambiaron (5.4) |
| 6. **Cobro mixto** | Si «A pagar» > 0: **Ctrl+Enter** abre el cobro; Enter en una fila vacía pone ahí lo que falta y cobra | Muestra filas fijas, solo las habilitadas: **Nómina** (con el cupo), **Efectivo** y **Tarjeta**. Se pueden combinar | F-4 y PF-4. Sin cupo configurado no hay fila de nómina. La tarjeta no pasa de lo que falta. La nómina no pasa del cupo |
| 7. **Cierre del consumo** | Nada | Emite el ticket interno, **borra la foto de la pantalla**, muestra el resultado con «**Queda en la bolsa RD$ 840.00**» en grande, imprime TK-01 y queda lista para el siguiente carné | AT-1 (todo o nada) y AT-2 (idempotencia con el `Uid` del documento) |

### 2.3 Visitante (F-02)

**F4** o [Visitante] abre el modo visitante en la misma ventana:
1. El panel del comensal se cambia por el panel **«Visitante»**, con el comprobante: *Consumo (E32)* por omisión, o *Crédito fiscal (E31)* con el RNC y la consulta a la DGII que ya existe.
2. La botonera es la misma, con la lista de precios de visitante. Las franjas aplican igual (PF-1) y no hay reparto.
3. El cobro usa `PanelCobroPos`, con efectivo y tarjeta; nunca nómina.
4. La emisión va por la ruta única, con `EsperaFirma` si el e-CF está activo ([DF] FD-06).
5. Se imprime la RI fiscal de la Estándar, no un ticket interno.
6. **Esc** o **F4** vuelve al modo comensal, pidiendo confirmación si hay líneas.

**El empleado que pide un comprobante fiscal** se atiende como visitante en esa compra, sin beneficios ([POS] F-02). La ventana no lo propone por su cuenta.

### 2.4 Reverso (F-04)

Desde [Consumos] en la cabecera (o la opción de menú «Consumos Internos»):
1. Se elige el ticket: los de la jornada, con búsqueda por número o por código del comensal.
2. Se marcan las líneas y las cantidades. Por cada línea se responde **«¿Se sirvió?»**.
3. Se ve **qué se devuelve**, en este orden: dinero, bolsa y almuerzo o cena ([POS] F-04).
4. Se escribe el motivo y se pide la **autorización de otra persona** (`DialogoAutorizacionSupervisor`, sin «Autorizo yo»).
5. Se emite el reverso y se imprime TK-03 con su propio saldo resultante (F-5).

Casos con mensaje propio:

| Caso | Qué dice la ventana | Qué hace |
|---|---|---|
| El consumo es de un mes ya cerrado | «La bolsa de septiembre ya cerró: esos RD$ 160.00 no se devuelven. Se devuelve solo el dinero del empleado.» | La bolsa no se reabre (51821) |
| El corte de nómina de ese período ya se exportó | «El corte de nómina del 01 al 15/10 ya se exportó. Este reverso lo hace el administrador del beneficio como un ajuste del período siguiente.» | No se ofrece a la caja |
| Después del Z de esa jornada | Solo el supervisor, desde «Consumos Internos» | El dinero sale de la caja abierta del día |

### 2.5 Identificación sin carné (F-08, H-08 (a))

1. [Sin carné] o **Ctrl+B** abre la búsqueda por código o por nombre (sin tildes, con el índice del núcleo).
2. La lista muestra **solo** el código, el nombre y la categoría. **No muestra miniaturas de fotos**: no hay galería.
3. Al elegir una persona se pide la autorización de otra persona, con el motivo.
4. Con la autorización, aparece la foto **de esa persona** y se sigue en «Por confirmar», como con el carné.
5. El panel muestra «Sin carné: 2 de 3 este mes».
6. Al llegar al límite: «Juan Pérez ya usó las 3 identificaciones sin carné de octubre. Debe pedir su carné a Recursos Humanos.» (UQ-2).

---

## 3. Pantallas

### 3.1 VC-01 · Ventana «Facturación Corporativa» (comensal identificado, almuerzo, ejemplo E-2 de [HF] 3.6)

Rejilla de **3/5/4** columnas a partir de 1280 px de ancho: comensal, botonera y consumo con cobro. Entre 1024 y 1279 px es **4/8**: el comensal arriba a la izquierda y la botonera debajo.

```
┌ Facturación Corporativa  [▣ Caja 02 · Comedor Planta]  [👤 Turno MPEREZ]  [🕛 Almuerzo 12:00–14:30 · quedan 38 min]  [● Central]   [Consumos] [Sin carné Ctrl+B] [Visitante F4] [Cierre X/Z] ┐
├ (bandas solo si hay algo que hacer: modo fiscal sin definir · sin conexión · licencia por vencer · fotos sin sincronizar) ────────────────────────────────────────────────────────────────────┤
│┌ COMENSAL ──────────────── ✓ confirmado ┐┌ ALMUERZO · 12:00–14:30 ──────────────────────────────────┐┌ CONSUMO ─────────────────────────────────────────┐│
││ ┌──────┐ JUAN PÉREZ GÓMEZ               ││ Composición: Plato fuerte 1/1 ✓ · Acompañante 1/1 ✓ ·     ││ 1 Pollo guisado      250.00  [🍽 Almuerzo 100 %]  ││
││ │ foto │ 004512 · Empleado              ││              Bebida 1/1 ✓                                ││ 1 Arroz blanco        60.00  [🍽 Almuerzo 100 %]  ││
││ │96×128│ Producción · Planta Haina      ││ [Almuerzo] [Siempre disponibles] [Otras franjas 🔒]       ││ 1 Jugo natural        60.00  [🍽 Almuerzo 100 %]  ││
││ └──────┘ F2 ver foto grande             ││ PLATO FUERTE                                             ││ 1 Postre del día      80.00  [👛 Bolsa 40.00]      ││
││ ─────────────────────────────────────── ││ [Pollo guisado ✓][Res guisada ][Pescado     ][Vegetariano]││                              [💵 Paga 40.00]       ││
││ 👛 Bolsa de octubre    RD$ 1,000.00     ││ ACOMPAÑANTE                                              ││ 1 Galletas           120.00  [👛 Bolsa 120.00]     ││
││ 🍽 Almuerzo hoy        Disponible       ││ [Arroz blanco ✓][Moro    ][Ensalada   ][Tostones   ]      ││ ─────────────────────────────────────────────────  ││
││ 🌙 Cena hoy            No aplica        ││ BEBIDA                                                   ││ ┌ pos-total ───────────────────────────────────┐  ││
││ 🧾 Cupo de nómina      RD$ 1,500.00     ││ [Jugo natural ✓][Agua     ][Refresco  ]                  ││ │ A PAGAR                           RD$ 40.00  │  ││
││    (01–15/10)                           ││ ──────────────────────────────────────────────────────── ││ │ Total del consumo                    570.00  │  ││
││ ⓘ Sin carné: 0 de 3 este mes            ││ Código [____________]  Enter agregar · F3 buscar · 2+código││ │ 🍽 Almuerzo (empresa)                370.00  │  ││
││                                         ││                                                          ││ │ 👛 Bolsa                             160.00  │  ││
││                                         ││                                                          ││ │ 💵 Paga el empleado                   40.00  │  ││
││                                         ││                                                          ││ │ BOLSA  1,000.00 → QUEDA 840.00               │  ││
││                                         ││                                                          ││ └──────────────────────────────────────────────┘  ││
││ [ Nuevo consumo (Esc) ]                 ││                                                          ││ [        Cobrar RD$ 40.00 (Ctrl+Enter)        ]   ││
│└─────────────────────────────────────────┘└──────────────────────────────────────────────────────────┘└─────────────────────────────────────────────────┘│
└──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
```

**Jerarquía visual:**
1. Antes de confirmar: la **foto grande** y el nombre.
2. Durante el consumo: **«A pagar»**, el reparto de cada línea y la línea **«QUEDA»** de la bolsa (F-5).
3. En el resultado: «**Queda en la bolsa RD$ 840.00**» y el vuelto.

**El botón principal cambia de texto, nunca de lugar:**
- «**Despachar (Ctrl+Enter)**», en verde, si «A pagar» es 0;
- «**Cobrar RD$ 40.00 (Ctrl+Enter)**», en verde, si es mayor que 0;
- deshabilitado con su motivo en el propio botón: «Requiere pago: no disponible en esta caja» (EC-11) o «Calculando…».

### 3.2 VC-01 en «Por confirmar» (antes de Enter)

```
│┌ COMENSAL ─────────────────── ? confirme ┐┌ ALMUERZO · 12:00–14:30 ───────────────────────────────────┐┌ CONSUMO ──────────────────────────────┐
││ ┌────────────────────┐                   ││                                                           ││                                       │
││ │                    │  JUAN              ││   (botonera y código deshabilitados, velo gris)            ││  Confirme la identidad para agregar   │
││ │      FOTO          │  PÉREZ GÓMEZ       ││   «Confirme la identidad para agregar artículos.»          ││  artículos.                            │
││ │    240 × 320       │  004512            ││                                                           ││                                       │
││ │                    │  Empleado          ││                                                           ││                                       │
││ │                    │  Producción        ││                                                           ││                                       │
││ └────────────────────┘                   ││                                                           ││                                       │
││ 👛 Bolsa de octubre RD$ 1,000.00 · 🍽 Almuerzo: Disponible · 🌙 Cena: No aplica · 🧾 Nómina RD$ 1,500.00 ││                                       │
││ [   ✓ Es la persona (Enter)   ]        [ ✗ No es la persona (Alt+N) ]   [ No atender (Esc) ]            ││                                       │
│└──────────────────────────────────────────────────────────────────────────────────────────────────────────┘└───────────────────────────────────────┘
```

- **Foto:** de 240 × 320 a 300 × 400 px (CSS), en proporción 3:4 y sin recortar. Si la foto tiene 3 años o más: aviso gris «Foto de 2022: pida a RR. HH. que la renueve.»
- **[✓ Es la persona]** es verde y mide 56 px de alto. **[✗ No es la persona]** va con contorno rojo, a **96 px o más** del primero, para evitar el toque equivocado en una pantalla táctil.
- **«No es la persona»** pide una confirmación: «¿Bloquear el carné ****1234 de forma preventiva? Retenga el carné y avise al supervisor.» [Bloquear] [Volver]. Queda en la bitácora y en RC-05. Solo la empresa lo desbloquea (AC-04). Ver el punto de contacto P-7.
- **«No atender» (Esc)** vuelve a la lista sin dejar rastro, salvo la lectura en la bitácora de seguridad (inferido; lo decide [SW]).
- **Inactividad:** si pasan 30 s sin confirmar, la foto se desenfoca y aparece «Foto oculta por inactividad. F2 para verla.» (6.2).

### 3.3 VC-02 · Botonera por franja (`BotoneraCapas` con datos de `corp`)

| Elemento | Regla |
|---|---|
| **Pestañas** | **[Franja vigente]**: los grupos de la composición en su orden y, debajo, los demás artículos de la franja. **[Siempre disponibles]**: los artículos sin franja. **[Otras franjas 🔒]**: solo para consultar |
| **Encabezado del grupo** | «PLATO FUERTE · 1/1 ✓», que avanza con las líneas que entran en la composición, según el servidor. Al completarse el grupo: «✓ completo · el siguiente va a la bolsa o lo paga el empleado» |
| **Botón** | 128 × 96 px como mínimo (140 × 120 en las tabletas, como [RM] 5.3), con el nombre en dos líneas, el precio de la lista del comensal y una insignia con la cantidad agregada. En los artículos al 50 %, la marca «½ bolsa». En los de cobertura 0 %, «Sin bolsa» |
| **Artículo de otra franja** | En gris, con 🔒 y «12:00–14:30». **Tocarlo no agrega nada:** aparece el aviso «Pescado frito solo se vende de 12:00 a 14:30.» |
| **Cambio de franja** | Automático, con la hora del servidor, **solo entre consumos**: nunca cambia la botonera con un consumo en curso. A los 10 minutos del fin: el chip de la cabecera se pone ámbar con «Almuerzo: quedan 10 min» |
| **Sin franja vigente** (entre comidas) | La pestaña se llama «Merienda» o, si no hay franja, «Siempre disponibles» |
| **Teclas** | **Alt+1 a Alt+9**: los nueve primeros botones de la pestaña activa, con el número en la esquina del botón. **Ctrl+Re Pág / Ctrl+Av Pág**: cambiar de pestaña. El orden de tabulación sigue el visual |
| **Código** | El campo de `EditorLineas`, con Enter, F3 y «2+código». Las lecturas del lector de artículos entran aquí |

**Datos que faltan:** el orden y la agrupación de los botones de la franja y de «Siempre disponibles». [DAT] tiene la composición, pero no el orden de la botonera (sección 8, D-1).

### 3.4 VC-03 · Líneas con su reparto (`RepartoBeneficios`)

```
1  Postre del día                    80.00   [👛 Bolsa 40.00] [💵 Paga 40.00]      ½ bolsa
1  Galletas                         120.00   [👛 Bolsa 120.00]                     ↻ reparto recalculado
1  Jugo natural (2.º, fuera de la composición)  60.00   [💵 Paga 60.00]
```

- **Tres fichas, siempre con icono y texto:**
  - 🍽 «Almuerzo 100 %» o «Cena 100 %», en verde;
  - 👛 «Bolsa RD$ x», en azul;
  - 💵 «Paga RD$ y», en ámbar, con el texto `#0b1f44`.
  
  Una línea puede llevar una sola ficha o dos (bolsa y paga), nunca tres: la línea que entra en la composición entra completa (FD-06).
- **Línea partida por el servidor:** dos jugos con un solo cupo en la bebida se convierten en dos líneas, «Jugo natural» y «Jugo natural (2.º, fuera de la composición)».
- **↻ «reparto recalculado»:** la ficha cambia y la línea parpadea **una vez** (un fundido de 600 ms, sin parpadeos repetidos) cuando una línea nueva cambia el reparto de otra (la bolsa paga de mayor a menor). `aria-live` anuncia: «Reparto actualizado: ahora paga 40 pesos.»
- **Mientras el servidor calcula:** la línea aparece al instante en gris, con «validando…». Si el servidor la rechaza (fuera de franja), la línea se va y queda el aviso EC-05.
- **Quitar una línea:** **Supr** sobre la línea con el foco, o el ícono ✕, según el permiso `EliminarArticulos` de la configuración del POS.
- **Cambiar la cantidad:** «2+código» o los botones − y + de la línea, según `CambiarCantidad`.

### 3.5 VC-04 · Panel del total y del saldo (F-5)

```
┌ pos-total ─────────────────────────────────┐
│ A PAGAR                          RD$ 40.00 │   ← Typo.h3; «Nada que pagar» en verde si es 0
│ Total del consumo                   570.00 │
│ 🍽 Almuerzo (empresa)               370.00 │
│ 👛 Bolsa                            160.00 │
│ 💵 Paga el empleado                  40.00 │
│ ────────────────────────────────────────── │
│ BOLSA DE OCTUBRE   1,000.00 → QUEDA 840.00 │   ← F-5, en vivo
│ CUPO DE NÓMINA     1,500.00                │   ← solo si la nómina está habilitada y la categoría la admite
└────────────────────────────────────────────┘
```

- La línea **«QUEDA»** se recalcula con cada cotización. Muestra lo que el servidor proyecta, no un cálculo local.
- Con la bolsa en 0: «BOLSA DE OCTUBRE: AGOTADA», en ámbar (EC-07).
- El cupo de nómina muestra «→ queda» solo cuando el cobro usa la nómina.

### 3.6 VC-05 · Cobro mixto (`RejillaCobro` de [DF], con una fila de nómina)

```
┌ Cobro · A pagar RD$ 40.00 ──────────────────────────────────────┐
│ 🧾 Nómina (01–15/10)  [        ]   cupo disponible RD$ 1,500.00   │
│ 💵 Efectivo           [  50.00 ]                                  │
│ 💳 Tarjeta            [        ]   Autorización [      ]          │
│ ──────────────────────────────────────────────────────────────── │
│ Recibido RD$ 50.00                      Falta RD$ 0.00            │
│ VUELTO   RD$ 10.00                                                │
│ [ Volver (Esc) ]                      [   Cobrar (Enter)   ]      │
└───────────────────────────────────────────────────────────────────┘
```

| Aspecto | Regla |
|---|---|
| Filas | Solo los medios habilitados por la empresa (`corp.FormaPagoHabilitada` y `NominaHabilitada`). La fila de nómina aparece solo si la categoría la admite (`PermiteNomina`) **y** hay cupo configurado (PF-4) |
| Orden y foco inicial | El orden lo fija la empresa (UQ-5). Por omisión: efectivo, nómina y tarjeta. El foco va a la primera fila |
| **Enter en una fila vacía** | Pone en esa fila lo que falta y cobra. En la nómina pone **lo que falta, hasta el cupo**. Si el cupo no alcanza: «El cupo de nómina cubre RD$ 25.00. Faltan RD$ 15.00 en efectivo o con tarjeta.» y el foco baja a la fila siguiente |
| Tarjeta | No pasa de lo que falta (la regla de [DF] FD-05) y pide la autorización si la forma lo exige. **La tarjeta se autoriza antes de emitir** (AT-4) |
| Nómina | No pasa del cupo: «Supera el cupo de nómina disponible (RD$ 1,500.00).» |
| Vuelto | Solo con efectivo, con el redondeo del núcleo de caja (`RedondeoVuelto`, `Pos.cs:29`) |
| Teclado | ↑ y ↓ cambian de fila; Supr vacía la fila; Esc vuelve a las líneas sin perder nada |

### 3.7 VC-06 · Resultado

```
┌───────────────────────────────────────────────────┐
│ ✓ Consumo CI-00012345 registrado                  │
│ QUEDA EN LA BOLSA            RD$ 840.00           │   ← Typo.h3, verde (F-5)
│ Vuelto                       RD$ 10.00            │   ← solo con efectivo
│ Almuerzo de hoy: tomado (este consumo)            │
│ [ Reimprimir ]          [ Nuevo consumo (Enter) ] │
└───────────────────────────────────────────────────┘
```

- **Al emitir, el panel del comensal se vacía al instante:** sin foto y con «Lea el carné del siguiente comensal.» El resultado solo muestra el número, el saldo y el vuelto. El nombre no aparece (6.2).
- El resultado queda en pantalla **hasta la siguiente lectura**, hasta Enter o durante 8 s como máximo; después, la ventana vuelve al estado «Lista».
- La impresión falla: «El consumo está registrado. No se pudo imprimir: <motivo>. [Imprimir otra vez]» (AT-3). **Nunca se ofrece «Despachar otra vez».**

### 3.8 VC-07 · Consumos de la jornada y reverso

Es una lista que reutiliza `ListaDocumentosEncontrados`, con estas columnas: número, hora, código del comensal, franja, total, almuerzo o cena, bolsa, paga y estado. **Sin nombre ni foto en la lista del cajero.** El nombre aparece solo en el detalle de un ticket.

El diálogo del reverso:

```
┌ Reverso del consumo CI-00012345 (12:14, 004512) ─────────────────────────┐
│ ☑ 1 Postre del día        80.00  Bolsa 40.00 · Paga 40.00  ¿Se sirvió? (•) No ( ) Sí │
│ ☐ 1 Galletas             120.00  Bolsa 120.00                            │
│ ─────────────────────────────────────────────────────────────────────── │
│ Se devuelve: 💵 RD$ 40.00 en efectivo · 👛 RD$ 40.00 a la bolsa          │
│ La bolsa quedará en RD$ 880.00                                            │
│ Motivo* [ Plato equivocado            ]                                  │
│ [ Cancelar (Esc) ]                       [ Pedir autorización (Enter) ]  │
└──────────────────────────────────────────────────────────────────────────┘
```

- **«¿Se sirvió?»** no tiene valor por omisión: hay que elegir una de las dos.
- Con **Sí**, el artículo no vuelve a la existencia y se crea un borrador de merma.
- Con **No**, el artículo vuelve a la existencia.

### 3.9 VC-08 · Visitante

Es el mismo armazón de VC-01, con el panel de la izquierda cambiado:

```
┌ VISITANTE ───────────────────────────┐
│ Comprobante (•) Consumo (E32)        │
│             ( ) Crédito fiscal (E31) │
│ RNC [_________] 🔍  Nombre [_______] │
│ Lista de precios: Visitante          │
│ [ Volver a comensal (F4) ]           │
└──────────────────────────────────────┘
```

Sin fichas de reparto. El cobro usa `PanelCobroPos`, con `EsperaFirma` para el e-CF.

---

## 4. Tickets impresos

**Reglas comunes:**
- La leyenda **«CONSUMO INTERNO – NO ES UN COMPROBANTE FISCAL»** va arriba y en negrita.
- **El ticket no lleva ITBIS** ni la palabra «factura», para que no se confunda con un comprobante. El ITBIS informativo queda en la base para la costura.
- No lleva cédula ni foto. El nombre va corto (el primer nombre y la inicial del apellido).
- **Los saldos salen de la instantánea guardada** en el ticket (`BolsaAntes`/`BolsaDespues`, `CupoNominaAntes`/`CupoNominaDespues` y `EstadoBeneficio` de [DAT] 4.6). La reimpresión muestra lo mismo que se imprimió, **nunca el saldo actual**.
- Se configuran por empresa: el cupo de nómina (`MostrarCupoNomina`, sí por omisión, FD-12) y el estado del almuerzo y la cena (parámetro nuevo `MostrarEstadoComidas`, sí por omisión: [HF] F-5 lo deja como opción del diseño; sección 8, D-3).
- Los tipos de formato nuevos son `TicketConsumoInterno` y `ReversoConsumo`, con plantillas de rollo de 80 y 58 mm, editables en el diseñador de formatos como las demás.

### 4.1 TK-01 · Ticket interno de 80 mm (ejemplo E-2 de [HF] 3.6, con un pago en efectivo)

```
            COMEDOR PLANTA HAINA
       EMPRESA EJEMPLO, S. A. · RNC <rnc>
------------------------------------------
  CONSUMO INTERNO – NO ES UN COMPROBANTE
                 FISCAL
------------------------------------------
Ticket CI-00012345       15/10/2026 12:14
Sede Planta Haina                Caja 02
Comensal 004512 · JUAN P.
Categoría Empleado · Almuerzo 12:00-14:30
------------------------------------------
Cant Descripción                  Importe
 1   Pollo guisado                 250.00
       Almuerzo 100 %              250.00
 1   Arroz blanco                   60.00
       Almuerzo 100 %               60.00
 1   Jugo natural                   60.00
       Almuerzo 100 %               60.00
 1   Postre del día                 80.00
       Bolsa (50 %)                 40.00
       Paga el empleado             40.00
 1   Galletas                      120.00
       Bolsa                       120.00
------------------------------------------
TOTAL DEL CONSUMO                  570.00
  Almuerzo (empresa)               370.00
  Bolsa de subsidio                160.00
  Pagado por el empleado            40.00
    Efectivo                        50.00
    Vuelto                          10.00
------------------------------------------
BOLSA DE SUBSIDIO · OCTUBRE
  Antes                          1,000.00
  Este consumo                    -160.00
  QUEDA                            840.00
CUPO DE NÓMINA · 01-15/10
  Queda                          1,500.00
ALMUERZO DE HOY: TOMADO (este ticket)
CENA DE HOY: no aplica a su categoría
------------------------------------------
Atendió MPEREZ
```

**Variantes:**

| Caso | Cambio en el ticket |
|---|---|
| Consumo sin dinero (E-1) | No lleva el bloque «Pagado por el empleado». La bolsa dice «Este consumo 0.00 · QUEDA 1,000.00» |
| Pago por nómina | «Nómina 01-15/10 ... 40.00», y el cupo con «Antes / Este consumo / Queda». Si la empresa lo pide, una línea de firma «Acepto el descuento por nómina: ______» (UQ-4) |
| Almuerzo ya tomado (E-5) | «ALMUERZO DE HOY: YA TOMADO 12:14 · Caja 2 (CI-00012301)». La línea va a la bolsa |
| Identificación sin carné | «Identificado sin carné · Autorizó SUPERV1» |
| Lote de contingencia | «CONTINGENCIA · Vale V-000123 del 15/10 12:20» |
| Con la costura en S-1 (si se firma) | Un bloque final: «Comprobante de la parte pagada: E32 · e-NCF <número>». La RI del E32 sale aparte, por la ruta única. Esta ventana no cambia |
| **Reimpresión** | «COPIA n» al pie y, si el ticket sirve para retirar la comida, «NO VÁLIDA PARA RETIRAR ALIMENTOS» (UQ-3) |

### 4.2 TK-02 · Ticket interno de 58 mm (el mismo ejemplo)

```
     COMEDOR PLANTA HAINA
  EMPRESA EJEMPLO · RNC <rnc>
--------------------------------
 CONSUMO INTERNO – NO ES UN
     COMPROBANTE FISCAL
--------------------------------
CI-00012345   15/10/2026 12:14
Planta Haina · Caja 02
004512 · JUAN P. · Empleado
Almuerzo 12:00-14:30
--------------------------------
Pollo guisado
 1 x 250.00            250.00
   Almuerzo 100 %      250.00
Arroz blanco
 1 x 60.00              60.00
   Almuerzo 100 %       60.00
Jugo natural
 1 x 60.00              60.00
   Almuerzo 100 %       60.00
Postre del día
 1 x 80.00              80.00
   Bolsa (50 %)         40.00
   Paga                 40.00
Galletas
 1 x 120.00            120.00
   Bolsa               120.00
--------------------------------
TOTAL                  570.00
 Almuerzo (empresa)    370.00
 Bolsa                 160.00
 Pagado                 40.00
  Efectivo              50.00
  Vuelto                10.00
--------------------------------
BOLSA OCTUBRE
 Antes               1,000.00
 Este consumo         -160.00
 QUEDA                 840.00
NÓMINA 01-15/10
 Queda               1,500.00
ALMUERZO HOY: TOMADO
CENA HOY: no aplica
--------------------------------
Atendió MPEREZ
```

En 58 mm la descripción va en su propia línea y la leyenda se parte en dos líneas centradas. Lo que no cambia en ninguno de los dos anchos: **la leyenda, el bloque de la bolsa con «QUEDA» y el estado de las comidas** (F-5).

### 4.3 TK-03 · Reverso de 80 mm (reverso parcial del postre de TK-01, no servido)

```
            COMEDOR PLANTA HAINA
       EMPRESA EJEMPLO, S. A. · RNC <rnc>
------------------------------------------
     REVERSO DE CONSUMO INTERNO
     NO ES UN COMPROBANTE FISCAL
------------------------------------------
Reverso RC-00000231      15/10/2026 12:31
Ticket original CI-00012345 (12:14)
Sede Planta Haina                Caja 02
Comensal 004512 · JUAN P.
Motivo: Plato equivocado
Autorizó SUPERV1 · Hizo MPEREZ
------------------------------------------
Cant Descripción                  Importe
 1   Postre del día                 80.00
       Servido: No (vuelve a existencia)
       A la bolsa                  +40.00
       Al empleado                 +40.00
------------------------------------------
DEVUELTO AL EMPLEADO                40.00
  Efectivo                          40.00
------------------------------------------
BOLSA DE SUBSIDIO · OCTUBRE
  Antes                            840.00
  Devuelto                         +40.00
  QUEDA                            880.00
ALMUERZO DE HOY: TOMADO (sin cambio)
------------------------------------------
```

**Variantes:**
- Si se reversa la comida del almuerzo: «ALMUERZO DE HOY: DISPONIBLE OTRA VEZ».
- Si el mes ya cerró: «Bolsa de septiembre cerrada: no se devuelve (160.00)», y la bolsa no lleva el bloque «Antes / Devuelto».
- Si el pago fue por nómina: «Nómina 01-15/10: se resta del corte −40.00» y el cupo con «Antes / Devuelto / Queda».

### 4.4 TK-04 · Reverso de 58 mm

Es la misma estructura de TK-02, con «REVERSO DE CONSUMO INTERNO» en dos líneas, el ticket original, el motivo, quién autorizó, las líneas con «Servido: No» y el bloque de la bolsa con «QUEDA».

---

## 5. Estados

### 5.1 Estados de la ventana y del comensal

| # | Estado | Qué ve el cajero (texto exacto) | Comportamiento |
|---|---|---|---|
| EC-00a | **Carga** | `MudProgressLinear` bajo la cabecera y la botonera en esqueleto | La sesión, la franja, la botonera y los parámetros se cargan una vez por jornada; la botonera se recarga al cambiar de franja. Meta: ≤ 2 s |
| EC-00b | **Lista (vacía)** | Panel del comensal: «Lea el carné del comensal.», con un icono de carné y «Sin carné: Ctrl+B · Visitante: F4» | Botonera visible pero deshabilitada |
| EC-00c | **Error al cargar** | «No se pudo preparar la caja: <mensaje del servidor>.» [Reintentar] | Nada se habilita |
| EC-00d | **Módulo no activo** (404 `MODULO_NO_ACTIVO`) | «El módulo Corporativa no está activo en esta empresa. Lo activa el SUPER.» | Sin venta |
| EC-00e | **Caja en otro modo** (422 `CAJA_MODO_DISTINTO`) | «Esta caja no está en modo Corporativa. Use la ventana de facturación de su caja o pida al administrador que la configure.» | Sin venta |
| EC-00f | **Sin permiso** (403) | «Su usuario no tiene permiso para despachar en Facturación Corporativa.» | La opción no aparece en el menú |
| EC-00g | **Jornada sin apertura o cerrada** | Chips de la Facturación Ágil: «Caja sin apertura hoy» y «Jornada cerrada · Z …» | Patrón actual (`PuntoVenta.razor:28-43`) |
| **EC-01** | **Carné desconocido** | Alerta ámbar: «Carné no registrado. Pida que lo lea otra vez. Si sigue igual, identifíquelo sin carné (Ctrl+B, con autorización) o atiéndalo como visitante (F4).» | Sin foto ni datos. Una lectura mal formada da: «Lectura incompleta. Lea el carné otra vez.» **Nunca se busca por coincidencia parcial** ([POS] H-1) |
| **EC-02** | **Carné perdido, bloqueado, reemplazado o vencido** | Alerta roja `role="alert"`: «Carné ****1234 reportado como PERDIDO. Retenga el carné y avise al supervisor.» (o «BLOQUEADO», «REEMPLAZADO por uno nuevo» o «VENCIDO el 30/09/2026») | **Sin foto y sin nombre**: el cajero no necesita más y protege el dato de la persona. Sonido de error. Queda en la bitácora y en RC-05. Ofrece [Sin carné (Ctrl+B)] para el dueño real con su autorización |
| **EC-03** | **Empleado inactivo** | Tarjeta en gris con la foto, para que el cajero vea quién es, y un sello: «SUSPENDIDO hasta 30/10/2026», «DE BAJA desde 01/10/2026» o «INHABILITADO». Luego: «No tiene beneficios. Puede atenderlo como visitante (F4).» | **Nunca se muestra el motivo** de la suspensión: el tercero no debe conocerlo. [Atender como visitante (F4)] [Cancelar (Esc)] |
| EC-04 | **Sin foto registrada o la foto no carga en 1,5 s** | Silueta con «Foto no disponible. Para confirmar hace falta la autorización de otra persona.» | [Pedir autorización] abre `DialogoAutorizacionSupervisor`. El ticket queda marcado (H-2, F-08) |
| **EC-05** | **Artículo fuera de franja (F-1)** | En la botonera, gris con 🔒. Al tocarlo o leerlo: aviso ámbar sobre el código, «Pescado frito solo se vende de 12:00 a 14:30. Hora del servidor: 16:02.» | La línea no se agrega. Si se lee con el lector: sonido de error. Lo mismo para el empleado y el visitante (PF-1). No hay botón para «saltarse» la franja |
| **EC-06** | **El almuerzo ya se usó (H-06 (a))** | En la tarjeta: «🍽 Almuerzo hoy: **ya tomado** a las 12:14 en la Caja 2». En la botonera: «La composición ya se usó hoy: lo que agregue va a la bolsa o lo paga el empleado.» | **No se bloquea**: el segundo plato va a la bolsa o al dinero (E-5) y sale en RC-05 |
| EC-06b | **Carné usado hace menos de 2 minutos en otra caja** (posible clonación, R-D3) | Alerta roja: «Este carné se usó a las 12:13 en la Caja 2. Compare la foto con cuidado.» | Exige **confirmar otra vez**: Enter no basta, hay que tocar o pulsar [Es la persona] después de leer el aviso. Queda en RC-05 |
| **EC-07** | **Bolsa agotada** | «👛 Bolsa de octubre: **AGOTADA**», en ámbar. En las fichas: «Paga RD$ …» | No se bloquea: el empleado paga (F-2 y A-B4). Con el modo fiscal sin definir, ver EC-11 |
| **EC-08** | **Cupo de nómina agotado** | En la tarjeta: «🧾 Nómina: cupo agotado (01-15/10)». En el cobro, la fila de nómina se deshabilita con «Cupo agotado». Si el cupo es parcial: «El cupo de nómina cubre RD$ 25.00…» (3.6) | El empleado paga en efectivo o con tarjeta (PF-4) |
| EC-08b | **La categoría no admite nómina** (personal de servicio) | Sin fila de nómina. Debajo del cobro, en gris: «Su categoría no tiene descuento por nómina.» | — |
| **EC-09** | **409: el saldo cambió en otra caja** | Diálogo `role="alertdialog"`: «La bolsa de este comensal cambió en otra caja mientras lo atendía (antes RD$ 300.00, ahora RD$ 120.00). El reparto se recalculó: ahora paga **RD$ 40.00** (antes RD$ 0.00).» [Aceptar y seguir (Enter)] [Revisar líneas (Esc)] | **No se emitió nada** (CA-07). Al aceptar: si «A pagar» sigue en 0, se despacha; si no, se abre el cobro con lo nuevo. **No se reintenta solo** (AT-9). El cupo de nómina y el almuerzo tomado en otra caja tienen la misma variante: «El almuerzo de hoy se registró hace un momento en la Caja 2…» |
| **EC-10** | **Sin conexión (H-10)** | Ver 5.3 | — |
| **EC-11** | **Modo fiscal sin definir (FD-09) o `S6`** | Banda roja **permanente** bajo la cabecera: «Esta caja todavía no puede cobrar dinero a los empleados. Solo se despachan consumos que cubre la empresa (almuerzo, cena y bolsa). Avise al administrador.» En el consumo con dinero: fichas «💵 Paga RD$ 40.00 · no disponible», en rojo, y el botón deshabilitado con «Requiere pago: no disponible en esta caja». Se ofrece [Quitar las líneas con pago] | El servidor rechaza el ticket con dinero (51815). La ventana lo anticipa con la cotización. Los visitantes no cambian. Para el administrador, la banda dice además «Tratamiento fiscal de la porción pagada sin definir (H-04).» (AC-11) |
| **EC-12** | **Visitante con NCF** | VC-08. Los estados del e-CF son los de [DF] FD-06 y FD-07: espera de la firma, constancia y «pendiente de validación» | Sin conexión no se atienden visitantes (R-O5) |
| **EC-13** | **Reverso con autorización** | VC-07. Si autoriza el mismo cajero: «Debe autorizar otra persona.» (51820), en el diálogo, con el foco en el usuario | Credencial rechazada: el mensaje se queda en el diálogo (`AUTORIZACION_INVALIDA`, X-5) |
| EC-14 | **Resultado desconocido** (el envío no recibió respuesta) | «No sabemos si el consumo se registró. **No lo repita.** Verificando…», en `aria-live="assertive"` | Se reenvía con el mismo `Uid` (AT-2). Si se emitió, se muestra el resultado normal. Si no, «El consumo no se registró. [Despachar otra vez]», con el mismo `Uid` |
| EC-15 | **Lectura de otro carné con un consumo en curso** | «Hay un consumo sin despachar de 004512. ¿Descartarlo y atender al siguiente?» [Descartar y leer (Enter)] [Volver (Esc)] | Nunca mezcla dos comensales. Si el consumo está en «Resultado», empieza el siguiente sin preguntar |
| EC-16 | **Límite de identificaciones sin carné** | «Juan Pérez ya usó las 3 identificaciones sin carné de octubre. Debe pedir su carné a Recursos Humanos.» | Bloqueante (UQ-2) |
| EC-17 | **Licencia del módulo por vencer o vencida** | `BandaVigencia` de [DF] | Con la licencia vencida no se despacha; se consulta y se reimprime |

### 5.2 Estados por zona

| Zona | Carga | Vacío | Error | Sin permiso | Sin conexión |
|---|---|---|---|---|---|
| Comensal (VC-01) | «Leyendo carné…» (≤ 1 s) | «Lea el carné del comensal.» | EC-01 a EC-04 | — | EC-10 |
| Botonera (VC-02) | Esqueleto | «No hay artículos configurados para esta franja. Avise al administrador.» | «No se pudo cargar la botonera.» [Reintentar] [Usar el código] | Sin búsqueda manual: el texto actual del editor (`EditorLineas.razor:26`) | La última botonera cargada, con su hora |
| Líneas (VC-03) | «validando…» en la línea | «Toque un artículo o lea su código.» | EC-05, unidad no vendible, `DialogoFaltantes` (`EXISTENCIA_INSUFICIENTE`) | Sin `EliminarArticulos`: sin ✕ | — |
| Total (VC-04) | «Calculando…» | «Nada que pagar» | EC-09, EC-11 | — | — |
| Cobro (VC-05) | «Registrando…» | — | 422 en la banda del cobro, con el foco en la fila | Medio no habilitado: la fila no existe | EC-14 |
| Consumos (VC-07) | Esqueleto de tabla | «No hay consumos en esta jornada.» | «No se pudo leer la lista.» [Reintentar] | Sin `reverso-consumo`: no aparece [Reversar] | — |

### 5.3 Sin conexión (H-10 (a)): tres capas, cada una con su nombre ([DF] 2.7)

| Capa | Efecto | Qué ve el cajero |
|---|---|---|
| **Caja ↔ servidor de la sede** (nodo o central) | **No se despacha** (la ventana corre en el servidor) | Capa de reconexión: «Se perdió la conexión con el servidor. Reconectando…». A los 30 s: «**Si la conexión no vuelve, siga el procedimiento de contingencia en papel** (vales numerados solo para el almuerzo y la cena; recibos para el dinero). No atienda visitantes.» Un cobro enviado queda en EC-14 |
| **Nodo ↔ central** (sede con nodo) | **Se despacha normal** con el padrón, las fotos y los saldos de la sede (R-O2). Si el comensal es de otra sede: almuerzo al 100 % sí, **bolsa no** y el resto lo paga (R-O3) | Chip ámbar «Central: sin conexión desde 12:05 · 34 consumos por subir». Para un comensal de otra sede: «👛 Bolsa no disponible sin conexión con su sede (Planta Norte). Lo que no cubra el almuerzo lo paga el empleado.» |
| **Internet** (e-CF del visitante) | Solo afecta al visitante con e-CF: constancia sin espera | Chip «e-CF: sin internet · 3 pendientes» |

**Lo que hay que preparar para la contingencia en papel**, porque la pantalla no puede ayudar si no hay servidor:
1. Un **talonario de vales numerados** que se imprime por adelantado desde AC-14.
2. Un **cartel del procedimiento**, impreso junto a la caja.
3. Al volver la conexión, una banda en VC-01: «Hay vales de contingencia por digitar. Entréguelos al administrador del beneficio.»

**AC-13 (Digitación de contingencia)** está en la sección 7.

### 5.4 Validaciones visibles: cuándo se muestran

- **Al agregar una línea:** franja, existencia y unidad (servidor).
- **Al cambiar el reparto:** ↻ en las líneas afectadas (3.4).
- **Al cobrar:** cupo, medio habilitado y modo fiscal. El servidor vuelve a validar todo y **sus mensajes ganan**.
- Los mensajes dicen **qué pasó y qué hacer**. No «Dato inválido», sino «El cupo de nómina cubre RD$ 25.00. Faltan RD$ 15.00 en efectivo o con tarjeta.»

---

## 6. Teclado, lector, pantalla táctil, accesibilidad y privacidad

### 6.1 Teclado (caja)

| Tecla | Dónde | Acción |
|---|---|---|
| (lectura de carné) | Cualquier lugar | Identificar. La detecta el prefijo del lector (6.3) |
| **Enter** | Por confirmar | ✓ Es la persona |
| **Alt+N** | Por confirmar | ✗ No es la persona (con confirmación) |
| **Esc** | Por confirmar / consumo / cobro / diálogo | No atender / descartar el consumo (con confirmación si hay líneas: «¿Descartar este consumo? No se ha registrado.») / volver a las líneas / cerrar |
| **F2** | Comensal | Ver la foto grande otra vez (miniatura o foto oculta) |
| Enter / F3 / «2+código» | Código | Agregar / buscar / cantidad (existente, `EditorLineas.razor:248-277`) |
| **Alt+1 a Alt+9** | Botonera | Los nueve primeros botones de la pestaña |
| Ctrl+Re Pág / Ctrl+Av Pág | Botonera | Pestaña anterior o siguiente |
| ↑ ↓ y **Supr** | Líneas | Moverse y quitar la línea |
| **Ctrl+Enter** | Consumo | Despachar (A pagar = 0) o ir al cobro |
| Enter (fila vacía) / ↑ ↓ / Supr | Cobro | Lo que falta en esa fila y cobrar / cambiar de fila / vaciar la fila |
| **F4** | Ventana | Visitante, y volver |
| **Ctrl+B** | Ventana | Identificar sin carné |
| Enter | Resultado | Nuevo consumo |

**Teclas que se evitan** (las mismas de [DF] 5.4, inferido; se verifican en Edge, Chrome y WebView2):
- F1, F5 (recarga), F6, F7, F9, F10, F11, F12, Ctrl+R y Ctrl+número.
- **F5 y Ctrl+R se capturan** en esta ventana con «¿Recargar? Se perderá el consumo en curso.».
- **Alt+número** no tiene acción en Chrome ni en Edge en Windows (inferido; verificar). Si choca, la alternativa es el teclado numérico con Bloq Num y el foco en la botonera.

### 6.2 Privacidad en pantalla: la foto no queda a la vista de la fila

| # | Medida | Detalle |
|---|---|---|
| PV-1 | **Foto grande solo mientras se confirma** | Después de Enter queda como miniatura de 96 × 128. **Al emitir, se borra** (no queda en el resultado). Sin acción durante 30 s en «Por confirmar», se desenfoca (`filter: blur`) con «Foto oculta por inactividad. F2 para verla.» |
| PV-2 | **Puesto físico** | Guía de instalación: el monitor mira al cajero, a 45° o más de la fila, y se recomienda un **filtro de privacidad** (USD 30 a 60 por pantalla, inferido). Si hay visor hacia el comensal (fase 2), **nunca muestra la foto** ([POS] H-2) |
| PV-3 | **Sin galería** | No hay miniaturas en las listas: ni en la búsqueda sin carné, ni en los consumos, ni en el padrón (AC-01). Una foto a la vez, siempre de una persona elegida |
| PV-4 | **Sin copia en el equipo** | La foto llega por una URL de un solo uso o como `blob:` que se revoca al borrarla. La respuesta lleva `Cache-Control: no-store`. La imagen lleva `draggable="false"` y sin menú contextual. **No es una protección real** (una foto de la pantalla siempre es posible); evita copias accidentales en el caché |
| PV-5 | **Datos mínimos al tercero** | Sin cédula (no existe), sin el motivo de una suspensión, **sin foto ni nombre en un carné bloqueado** (EC-02) y sin nombre en la lista de consumos ni en el resultado |
| PV-6 | **Ticket y anuncios** | Sin foto. Nombre corto. `aria-live` dice el nombre y el saldo solo en «Por confirmar» y en el resultado, nunca la foto ni el motivo |
| PV-7 | **Botón del ojo** | Los montos llevan `sensible` (X-2). **La foto también:** con la visibilidad oculta, se desenfoca igual |

**Lo que revisa el auditor-seguridad:** la Ley 172-13 y el consentimiento; si la foto es un dato sensible.

### 6.3 Lector de carné y lector de artículos

- **Los dos emulan un teclado.** Para distinguirlos, el **lector de carné se configura con un prefijo y un sufijo** (por ejemplo, `F13`, o `~C` al principio y Enter al final). Se configura por caja (sección 8, D-2).
- Para un QR que genera GPOS, el prefijo puede ir **dentro del contenido** («GPC:» más el identificador opaco), así que un solo lector de mano sirve para el carné y para los artículos.
- **Captura global** (`keydown` en el documento, en fase de captura): al ver el prefijo, la ventana desvía los caracteres hasta el sufijo y no los escribe en el campo que tenga el foco.
- **Sin prefijo configurado** se usa el tiempo entre teclas (menos de 30 ms por carácter, inferido) más Enter. Es menos fiable: se avisa en la configuración de la caja: «Sin prefijo, una lectura puede confundirse con lo que se teclea.»
- Lectura incompleta (sin sufijo en 300 ms): se descarta con «Lectura incompleta. Lea el carné otra vez.»
- **Sonidos** (se pueden apagar por caja): un tono corto de lectura aceptada y uno doble y grave de error (EC-01, EC-02, EC-05). No reemplazan al texto.

### 6.4 Pantalla táctil (tableta MAUI o PC táctil)

- Ningún objetivo táctil por debajo de **48 × 48 px**. Los botones de la botonera miden 128 × 96 (140 × 120 en tableta). [Es la persona] mide 56 px de alto y queda a 96 px o más de [No es la persona].
- Todo lo de la caja se hace sin teclado: [Despachar], [Cobrar], las filas del cobro con `TecladoNumerico` de [RM] (que se abre al tocar la fila) y [Visitante].
- Se quita una línea deslizándola **o** con su ✕. El deslizamiento nunca es la única forma.
- Para la tableta de 1280 × 800 vale la rejilla 4/8: el comensal y el total arriba, la botonera abajo.

### 6.5 Accesibilidad (WCAG 2.2 AA en lo que aplica a una caja)

- **Teclado completo** (2.1.1): el consumo, el cobro mixto, el reverso y la autorización se hacen sin ratón. El orden de tabulación sigue el visual (2.4.3). Los botones de la botonera son botones reales y enfocables.
- **Foco** (2.4.7 y 2.4.11):
  - visible, con el borde primario más un anillo de 2 px y nunca tapado por las bandas;
  - en «Lista», sobre el panel del comensal; tras confirmar, en el código; en el cobro, en la primera fila;
  - al cerrar un diálogo vuelve al origen (`EnfocarAsync`).
- **Estado nunca solo por color** (1.4.1): las fichas del reparto llevan icono y texto; los estados de la tarjeta («Disponible», «Ya tomado», «Agotada») van escritos; los artículos bloqueados llevan 🔒 y el horario.
- **Contraste** (1.4.3 y 1.4.11): texto 4,5:1; el ámbar con `#0b1f44`; el blanco sobre `.pos-total` (inferido 4,5:1 o más, se verifica). Las fichas verde y azul usan el texto oscuro sobre un fondo claro (por ejemplo, `#e6f4ea` con `#1e4620`, y `#e8eefc` con `#1f3a93`, inferido ≥ 7:1).
- **Anuncios** (`aria-live`):
  - en `polite`: «Juan Pérez, empleado. Bolsa: 1.000 pesos. Almuerzo disponible.», «Agregado: postre del día. Bolsa 40, paga 40.», «Queda en la bolsa: 840 pesos.»;
  - en `assertive`: EC-01, EC-02, EC-05, EC-09, EC-11 y EC-14.
- **Foto:** `alt="Foto para verificar la identidad de Juan Pérez"`. Sin descripción de los rasgos.
- **Tiempo** (2.2.1): la foto se oculta por privacidad, pero F2 la recupera sin perder nada. La autorización no tiene límite de tiempo.
- **Movimiento** (2.3.1): solo el fundido de 600 ms del reparto recalculado; nada parpadea más de 3 veces por segundo.
- **Números:** `NumeroDoc` para leer el número del ticket (X-4 de la revisión de numeración).

---

## 7. Pantallas de administración (solo para la empresa dueña, H-09)

Perfil **«Administrador del beneficio»**. El cajero y el supervisor de cafetería reciben 403 (CA-09) y estas opciones no aparecen en su menú. **Cada cambio deja una línea en la bitácora** con el antes y el después. Los catálogos siguen el patrón de las tablas existentes (`Tablas/Catalogos.razor`, `Clientes.razor`): lista con búsqueda y ficha en un diálogo o en una página.

### 7.1 AC-01 · Comensales (padrón)

```
┌ Comensales  [Buscar código o nombre ______]  Estado [Activos ▾]  Categoría [Todas ▾]  C. costo [Todos ▾]  Sede [Todas ▾]   [Importar] [Nuevo] ┐
│ Código  Nombre               Categoría   Centro de costo   Sede          Estado            Carné        Foto         Bolsa del mes        │
│ 004512  Pérez Gómez, Juan    Empleado    Producción        Planta Haina  Activo            ****1234 ✓   ✓ 2025      840 de 1,000         │
│ 004513  Rosario, Ana         Ejecutivo   Gerencia          Planta Haina  Suspendido 30/10  ****5521 ✓   ⚠ sin foto  —                    │
│ S-0031  Díaz, Pedro          Servicio    Seguridad Ext.    Planta Haina  Activo            ****7788 ⚠ vence 30/11  ✓ 2026   —          │
└───────────────────────────────────────────────────────────────────────────────────────────────────────────────── 1-50 de 312 ◄ ► ┘
```

- **Sin miniaturas**: la columna «Foto» dice ✓ con el año, «sin foto» o «⚠ antigua».
- Filtros rápidos: «Sin foto», «Foto antigua», «Carné por vencer» y «Sin carné activo».

### 7.2 AC-02 · Ficha del comensal (pestañas)

| Pestaña | Contenido | Reglas visibles |
|---|---|---|
| **Datos** | Código (inmutable después de crearlo: «El código de nómina no se cambia.»), nombres, apellidos, enlace opcional con un empleado de `rrhh` | Sin campo de cédula |
| **Asignación** | Categoría, centro de costo, sede de referencia y departamento **con vigencia**: [Nueva asignación desde …] y el historial debajo | La asignación vigente se resalta. Al cambiarla: «Los consumos anteriores conservan su categoría y su centro de costo.» |
| **Estado** | Activo · Suspender hasta [fecha] · Dar de baja desde [fecha] · Inhabilitar | La baja dice: «Desde el 01/10 no tendrá bolsa ni almuerzo. La foto se borrará el 30/12 (90 días).» Con consumos posteriores a la fecha de baja: aviso con el enlace a RC-05 |
| **Carné** | AC-04 | — |
| **Foto** | AC-05 | — |
| **Beneficios** | La bolsa del mes (asignado, días con derecho si fue un alta a mitad de mes, ajustes, usado y **queda**), el cupo de nómina del período y las **excepciones** por persona (bolsa o cupo, con monto, vigencia y motivo) | El ajuste manual de la bolsa (con motivo obligatorio) queda en el libro de movimientos |
| **Consumos** | Los últimos 30 días, sin foto, con el enlace a RC-01 | — |

### 7.3 AC-03 · Importación por plantilla

Reutiliza el patrón de `Admin/ImportacionesPage.razor`. Los pasos son cuatro:
1. **Descargar la plantilla** (CSV o Excel) con las columnas: código, nombres, apellidos, categoría, centro de costo, sede, departamento, fecha de alta, fecha de baja y estado.
2. **Subir el archivo.**
3. **Vista previa** con cuatro pestañas y su cantidad: «Altas 12 · Cambios 5 · Bajas 3 · Errores 2». En «Errores», cada fila con su motivo (por ejemplo, «Fila 14: la categoría “Ejecutiv” no existe.»). En «Bajas», las que dejarían a alguien sin bolsa a mitad de mes, resaltadas.
4. **Aplicar** («Aplicar 20 cambios. Las 2 filas con error no se importan.»), con el resumen.

**La importación no trae fotos ni carnés.**

### 7.4 AC-04 · Carnés (alta, pérdida y reposición)

```
┌ Carné ───────────────────────────────────────────────────────────────┐
│ Activo: ****1234 · RFID 125 kHz · emitido 02/01/2026 · sin vencimiento│
│ [Reportar pérdida] [Bloquear] [Reponer]                               │
│ Historial: ****0091 · Reemplazado 01/01/2026 · «Deterioro»            │
└───────────────────────────────────────────────────────────────────────┘
```

- **Alta:** «Acerque el carné al lector de esta PC o escriba el número.» Se elige la tecnología y, para el personal de servicio, el **vencimiento**. Si el identificador ya existe: «Ese carné ya está registrado (****1234) y no se puede reutilizar.»
- **Pérdida o bloqueo:** motivo obligatorio. Efecto: «El carné queda bloqueado al instante en línea y en los nodos en la próxima sincronización.»
- **Reposición:** «El carné ****1234 quedará REEMPLAZADO y **nunca podrá reactivarse**. ¿Continuar?», y después el alta del nuevo.
- **Desbloquear** un bloqueo preventivo de la caja («No es la persona»), con motivo. Un carné perdido o reemplazado no se desbloquea.

### 7.5 AC-05 · Foto

- [Subir imagen] o [Tomar con la cámara] (webcam en la Web; la cámara del equipo en MAUI).
- **Recorte guiado en 3:4**, con una guía de rostro centrado. La aplicación reduce la imagen a 300 × 400 px antes de enviarla (30 a 50 KB).
- **Consentimiento:** una casilla «El comensal autorizó el uso de su foto para identificarlo en la cafetería.» Si el auditor-seguridad concluye que hace falta (Ley 172-13), será obligatoria (UQ-7).
- Se ve la vista previa y «Foto tomada el …». Para cambiarla: «La foto anterior se reemplaza; no se guarda historial.»
- **No hay botón de descarga ni de exportación.**

### 7.6 AC-06 · Categorías y montos

| Columna | Edición |
|---|---|
| Código, descripción, clase (Empleado · Ejecutivo · Servicio) | Texto y selector |
| **Bolsa mensual** | El monto vigente y [Cambiar desde …], que crea una fila con vigencia. El historial va en un panel lateral. Aviso: «El cambio aplica a la bolsa del mes que empieza después de la fecha. La del mes en curso no cambia.» |
| **Cupo de nómina** por período | Igual. Vacío significa que no se ofrece la nómina (PF-4) |
| Admite nómina | Casilla (el personal de servicio, apagada por omisión) |
| **Franjas al 100 %** | Matriz categoría × franjas de comida, con casillas («Empleado: Almuerzo ☑ Cena ☐»). Así se resuelve el doble turno (H-06) |

### 7.7 AC-07 · Centros de costo

Código, descripción, código en el ERP y «organización externa» (para el personal de servicio). Un centro de costo con asignaciones se inhabilita, no se borra.

### 7.8 AC-08 · Franjas por sede

```
┌ Franjas · Sede [Planta Haina ▾] ─────────────────────────────────────────────────────┐
│ Código   Descripción  Inicio  Fin    Días             Comida al 100 %  Estado        │
│ DES      Desayuno     06:00   09:00  L M X J V · ·    No               Activa        │
│ ALM      Almuerzo     12:00   14:30  L M X J V S ·    Sí               Activa        │
│ CEN      Cena         19:00   01:00  L M X J V S D    Sí  ⓘ cruza la medianoche     │
│ Próxima ventana del Almuerzo: hoy 12:00-14:30 (en 2 h 10 min)                        │
└──────────────────────────────────────────────────────────────────────────────────────┘
```

- Los días se marcan con fichas de L a D. Si el fin es menor que el inicio: «Cruza la medianoche: los consumos de 00:00 a 01:00 cuentan como cena del día anterior.» (R-H1).
- Al guardar: «Los artículos con esta franja solo se venderán de 12:00 a 14:30, sin tolerancia.» (F-1 y PF-1).

### 7.9 AC-09 · Artículos de cafetería (franja por artículo y cobertura)

Es una rejilla editable en lote, con un filtro por categoría de artículo:

| Artículo | Precio comensal | Precio visitante | Franjas (sin selección = toda hora) | Cobertura de la bolsa | En la composición |
|---|---|---|---|---|---|
| Pollo guisado | 250.00 | 320.00 | [ALM ×] | (100) 50 0 | Almuerzo · Plato fuerte |
| Postre del día | 80.00 | 100.00 | — | 100 **(50)** 0 | — |
| Galletas | 120.00 | 140.00 | — | **(100)** 50 0 | — |

- **La cobertura es un control segmentado** con tres valores (FD-05): 100 % (por omisión), 50 % y 0 %.
- Se pueden seleccionar varias filas y usar [Asignar franja] o [Asignar cobertura].
- La ficha del artículo recibe la pestaña «Corporativa» con los mismos campos ([UXV] H11).
- **Precios:** el tercero los propone y la empresa los aprueba (H-01 (a)). La pantalla de propuestas queda pendiente de [SW] (P-9). Aquí se muestran solo los precios vigentes.

### 7.10 AC-10 · Composición del almuerzo y la cena

```
┌ Composición · Almuerzo (Planta Haina) ─────────────────────────────────────────┐
│ Grupo            Cantidad   Artículos que admite                               │
│ 1 Plato fuerte   [1]        [Pollo guisado ×][Res guisada ×][Pescado ×][+ ]    │
│ 2 Acompañante    [1]        [Arroz blanco ×][Moro ×][Ensalada ×][+ ]           │
│ 3 Bebida         [1]        [Jugo natural ×][Agua ×][Refresco ×][+ ]           │
│ [+ Grupo]                                                                      │
│ Ejemplo: Pollo + Arroz + Jugo = RD$ 370.00 al 100 %; un 2.º jugo va a la bolsa │
└────────────────────────────────────────────────────────────────────────────────┘
```

- Un artículo está en **un solo grupo** por franja (FD-06). Si se intenta ponerlo en dos: «Arroz blanco ya está en el grupo Acompañante.»
- Si el artículo no tiene esa franja: «Pollo guisado no tiene la franja Almuerzo. ¿Asignársela?»

### 7.11 AC-11 · Parámetros de la Corporativa

- **Medios del empleado:** Efectivo ☑ · Tarjeta ☑ · Nómina ☑. Periodicidad de la nómina: quincenal o mensual.
- **Orden de las filas del cobro** (UQ-5).
- **Ticket:**
  - imprimir el cupo de nómina (sí por omisión);
  - imprimir el estado del almuerzo y la cena (sí por omisión);
  - línea de firma en el descuento por nómina (UQ-4);
  - el ticket sirve para retirar la comida (UQ-3).
- **Identificación:**
  - límite de identificaciones sin carné por mes (3);
  - días para borrar la foto después de la baja (90);
  - años para renovar la foto (3).
- **Listas de precios por sede:** la del comensal y la del visitante.
- **Modo fiscal de la porción pagada:** solo lectura para todos, salvo el SUPER. Con el valor «**Sin definir**», una banda roja: «Mientras no se defina (H-04), las cajas no cobran dinero a los empleados.» Al cambiarlo, el SUPER escribe el motivo y queda la línea en `_LOG`.

### 7.12 AC-12 · Corte de nómina

```
┌ Corte de nómina ─────────────────────────────────────────────────────────────┐
│ Período       Estado     Comensales  Monto       Exportado                   │
│ 01-15/10      Abierto    212         RD$ 48,350  —                [Revisar]  │
│ 16-30/09      Cerrado    205         RD$ 45,120  01/10 08:12 · huella 9f3a…  [Descargar otra vez] │
└──────────────────────────────────────────────────────────────────────────────┘
```

- **[Revisar]:** la vista previa por comensal (código, nombre, monto, tickets y ajustes), sin foto ni cédula.
- **[Exportar y cerrar]:** «Se exportará el período 01-15/10 y quedará **cerrado**: después no se podrán reversar sus consumos desde la caja; las correcciones irán al período siguiente.» Formato CSV o Excel. Exportar y cerrar es una sola operación (AT-7).
- **[Descargar otra vez]:** devuelve **el mismo archivo** con su huella. Nunca se genera de nuevo.

### 7.13 AC-13 · Digitación de contingencia

Es una rejilla para digitar muchos vales rápido, solo con el teclado:

| Vale | Código del comensal | Fecha y hora real | Franja | Líneas (composición) | Recibo manual | Monto · Forma |
|---|---|---|---|---|---|---|
| V-000123 | 004512 → *Pérez Gómez, Juan* | 15/10 12:20 | ALM | [Plato, Arroz, Jugo] | — | — |
| V-000124 | 004513 → *Rosario, Ana* | 15/10 12:21 | ALM | [Plato, Moro, Agua, Postre] | R-0045 | 40.00 · Efectivo |

- Enter pasa al campo siguiente. El vale ya digitado se rechaza: «El vale V-000123 ya se digitó.»
- Una regla que no se cumple (por ejemplo, el almuerzo ya tomado) **no rechaza el vale**: la fila se marca «⚠ Excepción» y va a RC-05 (R-O5).
- Al terminar, «Registrar el lote (24 vales)» muestra el resumen.

### 7.14 AC-14 · Talonario de vales (preparación de la contingencia)

Genera un PDF con vales numerados por sede (desde, hasta), con estos campos:
- código del comensal;
- firma;
- franja;
- «Solo almuerzo o cena al 100 %».

Los números quedan reservados, para que AC-13 los valide. Ver P-10.

---

## 8. Componentes y guía para el frontend

### 8.1 Componentes nuevos en `GPOS.Componentes` (Web y MAUI)

| Componente | Responsabilidad | Parámetros y eventos principales |
|---|---|---|
| `TarjetaComensal` | Foto, datos, estados del día, saldos, avisos, confirmación y privacidad (PV-1, PV-7) | `Comensal` (DTO), `Estado` (Leyendo, PorConfirmar, Confirmado, Inactivo, Bloqueado), `FotoUrl` (de un solo uso), `SegundosOcultarFoto` (30); `AlConfirmar`, `AlRechazar`, `AlCancelar` |
| `LectorCarne` | Captura global del prefijo y el sufijo, tiempo entre teclas y sonidos (6.3) | `Prefijo`, `Sufijo`, `UmbralMs`; `AlLeer(string lectura)`, `AlLecturaIncompleta` |
| `BotoneraFranja` | Envoltura de `BotoneraCapas` ([RM]) con las pestañas de franja, el avance de la composición, los artículos bloqueados con su horario y Alt+1 a 9 | `Franjas`, `FranjaVigente`, `AvanceComposicion`, `Habilitada`; `AlElegir(articulo)` |
| `LineasConsumo` y `RepartoBeneficios` | Líneas con sus fichas, el estado «validando…» y ↻ | `Lineas` (con `MontoBeneficio`, `MontoBolsa`, `MontoEmpleado`, `Cambio`); `AlQuitar`, `AlCambiarCantidad` |
| `PanelSaldoCorporativo` | El total, el reparto y «Bolsa → QUEDA» (F-5) | `Cotizacion` |
| `RejillaCobro` (de [DF]) con la fila de nómina | Filas fijas, nómina con cupo, Enter = lo que falta | `Medios`, `CupoNomina`, `Falta`; `AlCobrar(pagos)` |
| `DialogoReversoConsumo` | Líneas, «¿Se sirvió?», vista previa de lo devuelto y motivo | `Consumo`; `AlConfirmar` → `DialogoAutorizacionSupervisor` con `PermitirPropio = false` |
| `BusquedaComensal` | Búsqueda sin carné sin miniaturas | `AlElegir(comensalId)` |

**Se reutilizan:**
- de lo existente: `EditorLineas` (solo el campo de código y su lógica), `DialogoAutorizacionSupervisor`, `DialogoMotivo`, `BotonImprimir`, `NumeroDoc`, `ListaDocumentosEncontrados`, `AvisoNumeroOcupadoVista` y `SelectorCatalogo`;
- de B: `PanelCobroPos` (visitante), `EsperaFirma`, `ChipEstadoConexion`, `BandaVigencia`, `DialogoFaltantes` y `TecladoNumerico`.

**No se toca `PuntoVenta.razor`.**

### 8.2 Estilo

- **Paleta** de X-3. Colores nuevos, solo para las fichas del reparto:
  - beneficio: fondo `#e6f4ea`, texto `#1e4620`, icono `Restaurant`;
  - bolsa: fondo `#e8eefc`, texto `#1f3a93`, icono `AccountBalanceWallet`;
  - paga: `Warning` de MudBlazor con texto `#0b1f44`, icono `Payments`;
  - no disponible: `Error`, con el texto «no disponible».
- **Tipografía:** Roboto, la de MudBlazor (`wwwroot/fonts/roboto`). Números tabulares en todo monto. «A pagar» y «QUEDA» en `Typo.h3` o `h4`.
- **Espaciado:** la rejilla de 8 px (`pa-3`, `gap-2`). Campos de 40 px y botón principal de 56 px.
- **Iconos** (Material): `Badge` (carné), `Restaurant`, `NightsStay` (cena), `AccountBalanceWallet`, `ReceiptLong` (nómina), `Lock` (fuera de franja), `PersonOff` (inactivo), `CreditCardOff` (carné bloqueado), `Visibility`/`VisibilityOff` (foto).

### 8.3 Guía de construcción (para el desarrollador-frontend)

1. **El servidor manda en el reparto.** La pantalla nunca calcula la bolsa ni el almuerzo: cada cambio de líneas envía **la lista completa** a la cotización con un número de secuencia, y **descarta las respuestas viejas** (de una secuencia menor). Así, tres toques rápidos no dejan un reparto desordenado.
2. **No bloquear los toques.** La línea se agrega al instante en «validando…». Si el servidor la rechaza, se quita y se avisa (EC-05). Nunca se deshabilita la botonera mientras se calcula.
3. **El `Uid` del ticket** se genera al confirmar la identidad y se reutiliza en todo reintento (AT-2). Se cambia solo con un consumo nuevo.
4. **El 409** (EC-09) trae el reparto nuevo. La pantalla lo muestra y pide aceptar. **No se reenvía sola.**
5. **La foto:**
   - se pide con la versión (`VersionFoto`) y nunca se reutiliza la de otra persona;
   - se borra del DOM y se revoca el `blob:` al emitir, al cancelar y al leer otro carné;
   - si no llega en 1,5 s, pasa a EC-04.
6. **La franja vigente** viene del servidor, con la hora del servidor y lo que falta para el fin. El chip de la cabecera cuenta los minutos localmente, pero **se vuelve a sincronizar en cada cotización**. La hora del equipo nunca decide nada.
7. **Prueba de regresión del flujo:** bUnit para `TarjetaComensal` (no habilita nada antes de confirmar; la foto se borra al emitir), `LectorCarne` (prefijo, sufijo, lectura incompleta y escritura normal sin prefijo), `RepartoBeneficios` (los ejemplos E-1 a E-7 de [HF] 3.6 se muestran con esos importes) y `RejillaCobro` (el cupo parcial de nómina y la tarjeta que no pasa de lo que falta).
8. **Medición en el piloto:** registrar en el cliente (sin datos personales) los tiempos de la lectura a la foto, de la foto a la confirmación, de la confirmación al despacho y de la emisión, para contrastarlos con 1.1.
9. **Web y MAUI:** la misma página sobre los componentes de `GPOS.Componentes`; solo el armazón es propio de cada anfitrión (ADR-04). La cámara de AC-05 es la única diferencia de plataforma.

### 8.4 Datos que faltan en [DAT] (entrega al arquitecto-datos)

| # | Dato | Para qué |
|---|---|---|
| D-1 | **Orden y agrupación de la botonera** por sede y franja, y la lista de «Siempre disponibles» (por ejemplo, `corp.BotonArticulo` con franja, grupo visual y orden) | VC-02. Hoy no se sabe qué artículos muestra la botonera ni en qué orden |
| D-2 | **Configuración del lector de carné por caja:** prefijo, sufijo y sonidos | 6.3 |
| D-3 | **`corp.Parametros.MostrarEstadoComidas`** (sí por omisión), **`FirmaNomina`** (UQ-4), **`TicketEsValeRetiro`** (UQ-3) y el **orden de las filas del cobro** (UQ-5) | TK-01 y VC-05 |
| D-4 | **Talonario de vales:** los rangos reservados por sede | AC-14 y la validación de AC-13 |
| D-5 | **Fecha de la última sincronización** del padrón y de las fotos en el nodo | Chip de la cabecera en las sedes con nodo ([POS] F-05) |

---

## 9. Datos requeridos de la API y puntos de contacto con [SW]

**[SW] no existía cuando escribí esto.** Los nombres de endpoints y de códigos son **propuestas** para alinear. Si [SW] ya los fijó con otro nombre, mandan los de [SW].

### 9.1 Existentes (verificado)

- `SesionPos`, `FormaPagoDto` y `PagoPos` (una lista de pagos), en `src/GPOS.Contracts/Ventas/Pos.cs:64`, `:107`, `:134-145`.
- La reimpresión con `ReimpresionRequest` y `EstadoImpresionDto` (`Reimpresion.cs`).
- La ruta única de la venta POS para el visitante.
- La autorización de supervisor (ADR-68).

### 9.2 Que da [DAT] (columnas listas, sin contrato de API)

- El reparto por línea.
- Las instantáneas `BolsaAntes`/`Despues`, `CupoNominaAntes`/`Despues`, `EstadoBeneficio` y `BeneficioPrevioId`.
- `VersionFoto` y `ModoIdentificacion`.
- Los estados del carné y del comensal, `SuspendidoHasta` y `FechaBaja`.
- `ModoFiscalPorcion`, `MostrarCupoNomina` y `LimiteSinCarneMes`.

### 9.3 Puntos de contacto (faltantes, para el arquitecto-software)

| # | Contrato o comportamiento | Lo que necesita la pantalla |
|---|---|---|
| **P-1** | **Resolver el carné** (por ejemplo, `POST /api/corp/carne/resolver` con la lectura cruda) | En una sola respuesta de ≤ 1 s: el comensal (código, nombre, nombre corto, categoría, centro de costo, sede), el estado del comensal y del carné (con `SuspendidoHasta` o `FechaBaja`, **sin motivo**), una URL de foto de un solo uso con su versión, el saldo de la bolsa y el **usado visto** (para la guarda optimista, [DAT] 4.3), el cupo de nómina y si la categoría lo admite, el estado del almuerzo y la cena de hoy (disponible / ya tomado con hora y caja / no aplica), las identificaciones sin carné del mes y **el uso del carné en otra caja en los últimos 2 minutos** (EC-06b). Para un carné bloqueado: **solo el estado y los últimos 4** (PV-5) |
| **P-2** | **Confirmar la identidad** | CA-01 exige que la API rechace las líneas sin confirmación. Hace falta un token de confirmación, o un borrador en el servidor, que la cotización y la emisión exijan, con quién confirmó y cuándo |
| **P-3** | **Cotizar** (por ejemplo, `POST /api/corp/consumos/cotizar`) | Por línea: la validación de la franja con la hora del servidor (rechazo con el horario de la franja), el reparto, la marca de **cambio** respecto de la cotización anterior y la partición de la línea en la composición. Además: los totales, la bolsa y el cupo **proyectados** (F-5), el avance de la composición por grupo, `MontoEmpleado` y si **se puede cobrar** (modo fiscal), y la franja vigente con lo que falta para su fin. Meta: ≤ 300 ms |
| **P-4** | **Emitir** | 409 con el reparto nuevo y los saldos antes y ahora, para el saldo cambiado, el cupo cambiado o el almuerzo ya tomado. 422 con código y texto para el modo fiscal sin definir, el medio no habilitado, el cupo insuficiente, el comensal inactivo y el carné no activo. Códigos propuestos: `SALDO_CAMBIADO`, `BENEFICIO_YA_USADO`, `CUPO_NOMINA_INSUFICIENTE`, `MODO_FISCAL_SIN_DEFINIR`, `MEDIO_NO_HABILITADO`, `ARTICULO_FUERA_DE_FRANJA`, `COMENSAL_INACTIVO` y `CARNE_NO_ACTIVO` |
| **P-5** | **La foto** | Una URL firmada de un solo uso o de vida corta, `Cache-Control: no-store`, y servida por el nodo en las sedes con nodo |
| **P-6** | **Autorización de otra persona** | El reverso y la identificación sin carné no aceptan «Autorizo yo». `DialogoAutorizacionSupervisor` necesita un parámetro para ocultarlo, y el servidor lo rechaza igual (51820) |
| **P-7** | **«No es la persona»: el bloqueo preventivo desde la caja** | El cajero del tercero no toca el padrón (H-09). Esta transición concreta del carné (Activo → Bloqueado, con el motivo «No es la persona en la caja») tiene que estar permitida a su perfil, o bien ser solo un registro en RC-05 sin bloquear (UQ-1) |
| **P-8** | **Contar las reimpresiones del ticket interno** | Hoy un documento sin NCF se reimprime libre y no se cuenta (X-6). Si el ticket sirve para retirar la comida, la copia debe contarse, decir «COPIA n» y aparecer en RC-05 (UQ-3) |
| **P-9** | **Propuestas de precio del tercero** con la aprobación de la empresa (H-01 (a)) | Pantalla y contrato pendientes; AC-09 solo muestra los precios vigentes |
| **P-10** | **Talonario de vales y lote de contingencia** | Reserva de rangos, endpoint del lote con la marca `Origen = 'L'` y las excepciones sin rechazo (R-O5) |
| **P-11** | **El modo de la caja y los parámetros en la sesión** | `SesionPos` (o una sesión propia) con el modo «Corporativa», la sede, la franja vigente, los medios habilitados, la nómina, **si se admite el dinero del empleado** (sin exponer el valor fiscal al cajero) y la configuración del lector |
| **P-12** | **Reverso:** consulta del ticket con lo que se puede devolver | Por línea: lo ya reversado (`doc.LineaSaldo` clase `I`), si el mes de la bolsa cerró y si el corte de nómina ya se exportó, para mostrar los casos de 2.4 **antes** de pedir la autorización |

---

## 10. Preguntas (pendientes de firma)

| # | Para | Pregunta | Recomendación |
|---|---|---|---|
| UQ-1 | Propietario | «No es la persona», ¿**bloquea** el carné desde la caja ([POS] F-01) o solo **registra** la excepción para que RR. HH. decida? | **Bloquear de forma preventiva**, con confirmación, y que el desbloqueo sea solo de la empresa. Detiene enseguida un carné prestado o clonado. El riesgo de que un cajero bloquee por error es bajo y se corrige en AC-04 |
| UQ-2 | Propietario | Al pasar el límite de 3 identificaciones sin carné por mes, ¿se **rechaza** o se permite con otra autorización ([POS] F-08 lo permitía)? [HF] H-08 solo dice «un límite de 3» | **Rechazar** (EC-16): con el límite pasado, el comensal necesita su carné. Si no, el límite no limita |
| UQ-3 | Propietario | ¿El ticket se usa para **retirar la comida** en la línea de servicio? | Si se usa: la copia se cuenta y dice «COPIA n · NO VÁLIDA PARA RETIRAR ALIMENTOS» (P-8). Si no: la reimpresión es libre, como hoy para los documentos sin NCF. Parámetro por empresa, **sí por omisión** |
| UQ-4 | Contador (con CF-1) | ¿El descuento por nómina necesita la **firma del empleado** en el ticket (Código de Trabajo, art. 201)? | Una línea de firma opcional por empresa, **apagada** hasta la respuesta del contador |
| UQ-5 | Propietario | ¿Qué fila del cobro va primero (efectivo, nómina o tarjeta)? | Por empresa. Por omisión, **efectivo**, que es lo más común en una cafetería (inferido) |
| UQ-6 | Propietario | ¿Quién digita el lote de contingencia: la empresa o el supervisor del tercero? | **La empresa** (el administrador del beneficio). Si lo digita el tercero, puede inflar su liquidación (RO-3). Cuesta más trabajo a RR. HH. en los días de corte |
| UQ-7 | Auditor-seguridad | ¿El consentimiento de la foto es obligatorio (Ley 172-13)? | La casilla de AC-05, obligatoria si el auditor lo confirma |
| UQ-8 | Propietario | La opción «No usar mi bolsa» de [POS] A-B9, que [HF] no recogió, ¿se incluye? | **No en la fase 1:** suma una tecla y un caso al reparto sin un pedido del propietario |
| UQ-9 | Propietario | Con el modo fiscal sin definir (EC-11), ¿se ofrece «Atender como visitante» para cobrar el resto con comprobante? | **No ofrecerlo automáticamente:** sería el cajero eligiendo la ruta fiscal. El empleado puede pedirlo (F-02) |

---

## 11. Esfuerzo (solo interfaz, Web y MAUI sobre `GPOS.Componentes`; inferido ±40 %)

| Pieza | sp |
|---|---|
| VC-01 a VC-06 (comensal, lector, botonera, reparto, saldo y cobro con nómina) | 1,0 |
| VC-07 (consumos y reverso) y VC-08 (visitante, con lo de B) | 0,35 |
| TK-01 a TK-04 (cuatro plantillas de rollo) | 0,15 |
| AC-01 a AC-05 (padrón, ficha, importación, carnés y foto) | 0,6 |
| AC-06 a AC-11 (categorías, centros de costo, franjas, artículos, composición y parámetros) | 0,5 |
| AC-12 a AC-14 (corte, contingencia y talonario) | 0,3 |
| **Total** | **≈ 2,9 sp** (de 1,7 a 4,1) |

Esto cabe dentro de las piezas de [HF] 8.1: ventana, carné, padrón, reverso, nómina y contingencia, que suman ≈ 3,7 sp con el servidor incluido. Si `BotoneraCapas`, `RejillaCobro` y `PanelCobroPos` todavía no existen cuando empiece este tramo, se suman ≈ 0,4 sp, que se descuentan de Restaurante y Duty Free.

---

## Resumen breve

- **Ventana propia «Facturación Corporativa»** con la rejilla 3/5/4 y el estilo de la Facturación Ágil. El flujo es: lectura del carné, **foto grande**, **Enter para confirmar** (sin confirmar no se agrega nada), botonera por franja con el avance de la composición, **reparto por línea** en tres fichas (almuerzo, bolsa y paga), **«Bolsa → QUEDA» en vivo** (F-5), Ctrl+Enter para despachar o cobrar y el cobro mixto en filas fijas (efectivo, nómina con cupo y tarjeta). La meta es de **9 a 11 s** por consumo sin dinero.
- **Estados EC-01 a EC-17.** Entre ellos: el carné bloqueado **sin foto ni nombre**, el inactivo **sin el motivo**, la franja que bloquea con su horario, el almuerzo ya tomado que no bloquea, el **409 con el reparto nuevo y sin reintento automático**, las tres capas de conexión con la contingencia en papel y el **modo fiscal sin definir (FD-09)** con una banda roja, las fichas «no disponible» y [Quitar las líneas con pago].
- **Tickets de 80 y 58 mm** (consumo y reverso). Llevan la leyenda, el reparto, el bloque «Antes / Este consumo / QUEDA» desde la instantánea, el cupo de nómina y el estado del almuerzo y la cena. **Sin ITBIS.** La copia lleva «COPIA n».
- **Administración solo para la empresa** (AC-01 a AC-14): padrón **sin galería de fotos**, importación con vista previa, carnés con reposición irreversible, foto con recorte 3:4 y sin descarga, categorías con montos y vigencia, franjas, artículos con cobertura 0, 50 o 100, composición, parámetros, corte de nómina con «Exportar y cerrar», y la contingencia.
- **Privacidad (PV-1 a PV-7):** la foto grande solo mientras se confirma; miniatura después; borrada al emitir; desenfocada por inactividad; sin caché; puesto orientado al cajero con filtro de privacidad.
- **Coordinación:** [SW] no existía. Quedan 12 puntos de contacto (P-1 a P-12), 5 datos que faltan en [DAT] (D-1 a D-5) y 9 preguntas (UQ-1 a UQ-9).

### Cierre
- Estado: Completado (diseño; UQ-1 a UQ-9 **Pendientes de firma**; H-04 sigue abierta)
- Artefactos: `C:\Users\lfmen\source\repos\GPOS-NG-Equipos\traspasos\A\ux-vertical-corporativa-2026-10-15.md` (sin commit)
- Supuestos:
  - las metas de tiempo, el reparto de los medios de pago (70/25/5) y los costos del filtro de privacidad son inferidos;
  - 42 y 32 columnas para 80 y 58 mm a 8 y 7 pt (inferido de `PlantillasRazor.Rollo.cs`);
  - que Alt+número y Ctrl+Re Pág no chocan con el navegador (se verifica);
  - los contrastes de las fichas son inferidos;
  - los nombres de endpoints y códigos son propuestas hasta conocer [SW];
  - [POS] se lee con las correcciones de [HF] (sin beneficio C, franja que bloquea, tolerancia 0).
- Decisiones candidatas a ADR: ninguna nueva de arquitectura. La regla «el ticket interno cuenta sus copias si sirve para retirar la comida» (UQ-3 y P-8) precisa VE-01 de ADR-68 si se firma.
- Entregas a otros agentes:
  - arquitecto-software → P-1 a P-12 (en especial P-2, la confirmación en el servidor; P-3, la cotización con la marca de cambio; P-4, el 409 con el reparto nuevo; y P-7, el bloqueo preventivo);
  - arquitecto-datos → D-1 a D-5;
  - auditor-seguridad → PV-1 a PV-7, UQ-7 y la foto por URL de un solo uso;
  - especialista-contable → UQ-4 con CF-1;
  - desarrollador-frontend → la sección 8 cuando se construya en la entrega 3.
- Próximo paso recomendado: cotejar este diseño con [SW] en cuanto exista (P-1 a P-4) y llevar UQ-1 a UQ-3 al propietario junto con FD-01 a FD-15.
