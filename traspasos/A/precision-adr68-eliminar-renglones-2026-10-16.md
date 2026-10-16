# Precisión de ADR-68: eliminación de renglones del POS (SC08-01 y SC08-03)

```
[Decisión preparada por el Arquitecto Maestro, equipo A]   Estado: Propuesto · Pendiente de firma
Fecha: 2026-10-16
Origen: decisión del propietario (sesión de A, 2026-10-16): «Sí, tómalo después de DL-22»
Cierra: P-11 de la hoja de cierre de la ola 3 (ADR-68), en lo que toca a la eliminación de renglones
Código leído: GPOS-NG-autoriz @ f02cc777 (PR #49, sobre feature/modelo-ng ce33b2a8). No se compiló ni se modificó nada.
```

Convención: **[V]** lo verifiqué en el código · **[I]** es una inferencia o una estimación. Las rutas son relativas a `GPOS-NG-autoriz`.

---

## 1. Qué pasa hoy

| # | Hecho | Evidencia |
|---|---|---|
| H-1 | Al eliminar un renglón, la pantalla pide la autorización solo si el cajero no tiene `EliminarArticulos` (configuración POS del usuario) ni `eliminarrenglon` (privilegio). La decisión de quitar el renglón la toma la pantalla. | [V] `src/GPOS.Web/Components/Pages/Ventas/PuntoVenta.razor:495-503` (`:497`); `src/GPOS.Web/Components/Compartidos/EditorLineas.razor:351-355`; la copia de MAUI es igual: `GPOS.UI.MAUI/Components/Pages/Ventas/PuntoVenta.razor:497` |
| H-2 | El diálogo solo pide usuario y contraseña (no pide motivo y no ofrece la forma B). Llama a `POST /api/pos/autorizar`, que devuelve `true` o `false`, y cierra con «autorizado». | [V] `DialogoAutorizacion.razor:40-52` (`:47`); `src/GPOS.Web/Servicios/ApiClient.Modulos.cs:96` |
| H-3 | El servidor valida la credencial, pero no emite ninguna ficha ni ata la respuesta a la venta. Solo el rechazo deja un aviso en el registro; la autorización concedida no deja rastro. | [V] `src/GPOS.Api/Endpoints/PosEndpoints.cs:44-80` (`:76-79`) |
| H-4 | `VentaPos` no lleva eliminaciones ni autorizaciones: el servidor solo recibe la venta final. | [V] `src/GPOS.Contracts/Ventas/Pos.cs:147-191` |
| H-5 | `doc.Autorizacion` no admite `ELIMINA_RENGLON` y no tiene columnas para el artículo ni la cantidad. La tabla tiene `Linea`, `Tipo`, `AutorizadoPor`, `Valor` y `Motivo`, y `DocumentoId` es obligatorio. | [V] `src/GPOS.Core/Datos/Empresa/Configuracion/DocConfiguracion.cs:114-116`; `src/GPOS.Core/Dominio/Numeracion/Documentos.cs:111-122` |
| H-6 | El validador común ya hace lo que hace falta: forma A (otra persona, antes de la contraseña, sin el SUPER), forma B (privilegio Autorizar de la sesión), bitácora de rechazos y registro dentro de la transacción del documento. El autorizante debe tener `Autorizar` en la opción que se pasa. | [V] `src/GPOS.Core/Servicios/Nucleo/AutorizacionesSupervisor.cs:79-136` (forma B en `:95-101`); `:167-173`; `src/GPOS.Core/Sistema/AutorizadorSupervisor.cs:40` |
| H-7 | La devolución del POS ya sigue ese patrón: separa la contraseña antes de la huella de idempotencia, la valida y la registra. | [V] `src/GPOS.Core/Servicios/PosService.cs:607-613`, `:623`, `:704` |
| H-8 | «Punto de venta · Autorizar» solo se usa para eliminar renglones. La migración del modelo anterior lo concede a quien tenía `eliminarrenglon`, y el perfil «Supervisor» trae los dos. | [V] búsqueda en `src`: único uso en `PosEndpoints.cs:77`; `PermisosService.cs:112`, `:353`, `:356` |
| H-9 | La descripción del privilegio es «Eliminar renglones en POS sin autorización»: lo exime de pedirla, no lo hace autorizante. | [V] `src/GPOS.Contracts/Seguridad/Permisos.cs:269` |
| H-10 | **«Nueva venta» descarta la venta en curso, con todos sus renglones, sin pedir autorización y sin dejar rastro.** | [V] `PuntoVenta.razor:447-452` |
| H-11 | La interfaz Web es Blazor Server: el código de la pantalla corre en el servidor de `GPOS.Web` y el cajero no puede modificarlo desde el navegador. MAUI sí corre en el equipo. | [V] `src/GPOS.Web/Program.cs:14`, `:153` |
| H-12 | No existen ventas en espera. El POS no tiene un modo sin conexión en el cliente: toda venta se guarda por la API. | [V] búsqueda de «espera», «sin conexión» y «offline» en las páginas del POS y en `src` |

**Lectura honesta del riesgo.**
- El servidor solo puede validar lo que la venta le dice. Ninguna opción impide que un cliente manipulado (MAUI alterado, o la API llamada directamente con el token del cajero) quite un renglón **sin declararlo**: con su propio token, el cajero ya puede enviar una venta con menos artículos [I].
- Lo que ganan las opciones (a) y (b) es la **traza confiable**: quién autorizó qué, cuándo, en qué venta y por cuánto. Con esa traza se puede hacer el reporte de eliminaciones por cajero y supervisor (RC-05 o equivalente) y las auditorías del negocio.
- Prevenir el *sweethearting* de raíz exigiría un diario de escaneo en el servidor (cada renglón registrado al escanearlo). Eso cuesta unas 1,5 a 3 sp [I] y no lo recomiendo para la entrega 1.
- El hueco más directo hoy no es la eliminación, sino **descartar la venta completa** (H-10). Va en la casilla 3.

## 2. Opciones para SC08-01 (casilla 1)

| | (a) La venta lleva sus eliminaciones (**recomendada**) | (b) Ficha de un solo uso | (c) Solo la bitácora en el momento | (d) Ninguna |
|---|---|---|---|---|
| **Qué es** | `VentaPos.Eliminaciones[]`: artículo, unidad, cantidad, precio, importe y `AutorizacionSupervisor` (o nada, si es privilegio propio). `VenderAsync` separa las contraseñas antes de la huella, las valida con `ValidarAsync` (opción Punto de venta) **antes de abrir la transacción** y escribe una fila `ELIMINA_RENGLON` por eliminación en `doc.Autorizacion`, más su línea en la bitácora del documento. Si falta una autorización o no vale, rechaza toda la venta con 422 `AUTORIZACION_INVALIDA`. | `/api/pos/autorizar` valida la credencial en el momento y guarda una ficha (usuario, caja, artículo, cantidad, importe, autorizante, motivo, vencimiento) en una tabla nueva. La venta envía los identificadores de las fichas; `VenderAsync` las consume una sola vez y escribe `doc.Autorizacion`. | `/api/pos/autorizar` recibe el artículo, la cantidad y el importe, y escribe una línea en `audit.Bitacora` al autorizar. La venta no cambia. | Se acepta el riesgo residual tal como está. |
| **Costo [I, ±40 %]** | 0,35 a 0,5 sp | 0,6 a 0,9 sp | 0,1 a 0,15 sp | 0 |
| **Encaje con ADR-68** | Total: la autorización va «en la misma petición» y queda en `doc.Autorizacion` dentro de la transacción. | Se aparta de «en la misma petición». Se parece a la opción C que ADR-68 descartó. | No cumple: no hay fila en `doc.Autorizacion` ni vínculo con el documento. | Deja P-11 cerrado solo por aceptación. |
| **Qué rompe** | Contrato aditivo (`Eliminaciones` es opcional; un cliente viejo sin eliminaciones no cambia). Web y MAUI: el diálogo gana un motivo y la forma B, y la pantalla conserva la eliminación hasta cobrar. Esquema: `ELIMINA_RENGLON` en `CK_Autorizacion_Tipo`, más `ArticuloId` y `Cantidad` anulables en `doc.Autorizacion` (o una tabla hija; la forma la fija el arquitecto-datos). | Lo de (a), más una tabla, la limpieza de las fichas vencidas y el manejo de la ficha en la pantalla. | Solo el endpoint y el diálogo. | Nada. |
| **Ventas en espera** | Hoy no existen (H-12). Si se construyen, **no pueden guardar contraseñas**: tendrían que pasar a (b) para esas ventas. | Funcionan sin problema. | Funcionan. | — |
| **Sin conexión / ADR-53** | Sin efecto hoy (H-12). En el nodo de sucursal (entrega 2), la validación corre en la API del nodo, que ya necesita los usuarios replicados para iniciar sesión. | Igual, con la tabla de fichas local en el nodo. | Igual. | — |
| **Riesgo residual** | Bajo. La contraseña del supervisor queda en la memoria de la venta en curso hasta cobrar: en Web, en el circuito del servidor de `GPOS.Web`; en MAUI, en el equipo. Nunca se guarda ni se registra. Si el supervisor queda bloqueado antes del cobro, se rechaza la venta y hay que pedir otra autorización. El cliente manipulado que no declara la eliminación no se detecta (vale para todas las opciones). | Bajo. No retiene la contraseña, pero tiene más piezas que pueden fallar. | Medio: la traza no se puede cruzar con el documento y la puede alterar quien edite la bitácora. | Medio (R-6 sigue igual). |

**Privilegio propio (`eliminarrenglon` o la configuración `EliminarArticulos`).** Recomiendo que **se registre igual**, sin pedir autorización ni motivo, como la reimpresión con privilegio propio (VE-01, F-5).
- La venta declara la eliminación sin `AutorizacionSupervisor`.
- El servidor comprueba en la sesión el privilegio o la configuración POS del usuario, sin confiar en lo que diga el cliente.
- Graba la fila `ELIMINA_RENGLON` con el cajero como autorizante y la marca «(privilegio propio)».

Así el reporte por cajero queda completo. El costo está incluido en (a) [I].

**Motivo.** Cuando autoriza otra persona, el motivo es obligatorio, como en todo ADR-68: el validador lo exige (`AutorizacionesSupervisor.cs:89-90`, [V]). Con el privilegio propio, no se pide.

## 3. SC08-03: quién puede autorizar (casilla 2)

| | (i) **Recomendada**: autoriza quien tiene «Punto de venta · Autorizar» | (ii) Propuesta del auditor: autoriza quien tiene `eliminarrenglon` |
|---|---|---|
| Regla | Autoriza a otros el ADMIN de la empresa o quien tenga «Punto de venta · Autorizar», que es lo que ya comprueba `ValidarAsync` con la opción Punto de venta (H-6). `eliminarrenglon` y `EliminarArticulos` solo eximen al propio cajero (H-9). Quien tiene «Autorizar» y no tiene `eliminarrenglon` usa la forma B: confirma con su motivo. | Se quita «Autorizar» de la condición (`PosEndpoints.cs:77`) y `eliminarrenglon` recibe la acción Autorizar (patrón de `reimprimircomprobante`, `Permisos.cs:272-273`). |
| Ventaja | Una sola regla, la del validador común. Separa «me eximo» de «autorizo a otros»: dar `eliminarrenglon` a un cajero rápido no lo convierte en supervisor. | Es el cambio más pequeño en el endpoint actual. |
| Qué rompe | Un perfil a medida con `eliminarrenglon` y sin «Autorizar» deja de autorizar a otros. Los perfiles sembrados y los migrados traen los dos (H-8), así que no afecta a nadie hoy. | Quien tenga el privilegio para eximirse pasa a autorizar a otros. «Punto de venta · Autorizar» queda sin uso. |
| Costo [I] | < 0,05 sp en el servidor (el endpoint `/autorizar` pasa a usar `ValidarAsync`), más la forma B del diálogo, que ya está en (a). | < 0,05 sp |

## 4. Descartar la venta en curso (casilla 3, aparte)

Hoy, «Nueva venta» con renglones no pide nada ni deja rastro (H-10). Sin esto, la casilla 1 se elude descartando la venta y volviendo a escanear menos artículos.

**Propuesta:**
- Descartar una venta con renglones exige la misma regla que eliminar: privilegio propio, forma B o supervisor.
- El servidor deja una línea en `audit.Bitacora` con el cajero, la caja, el número de renglones, el importe y el autorizante. No hay documento al que atarla.
- Costo: 0,1 a 0,15 sp [I].

## 5. Texto de la precisión para ADR-68 (si se firma lo recomendado: 1a, 2i y 3 sí)

> **Precisión del 2026-10-16 (SC08-01 y SC08-03 de la revisión de seguridad de SEG-CORP-08; firmada por Leonardo Méndez, propietario, el AAAA-MM-DD).** Cierra P-11 de la hoja de cierre de la ola 3 en lo que toca a la eliminación de renglones del POS.
> 1. **La venta lleva sus eliminaciones.** Toda eliminación de un renglón del POS viaja en la venta (`VentaPos.Eliminaciones`) con el artículo, la unidad, la cantidad, el precio y el importe. Si no hay privilegio propio, lleva también el bloque `Autorizacion { Usuario, Clave, Motivo }`.
> 2. **Validación y registro.** El servidor separa la contraseña antes de la huella de idempotencia y la valida con el validador común (opción Punto de venta, formas A y B, SEG-CORP-08 y el punto 8 de ADR-81). Dentro de la transacción de la venta, registra cada eliminación en `doc.Autorizacion` con el tipo `ELIMINA_RENGLON` (quién autorizó, cuándo, artículo, cantidad e importe en `Valor`) y deja su línea en la bitácora del documento. Si falta una autorización o no vale, se rechaza la venta completa con 422 `AUTORIZACION_INVALIDA`. La contraseña no se guarda ni se registra.
> 3. **Privilegio propio.** Quien tiene `eliminarrenglon` o la configuración POS `EliminarArticulos` elimina sin pedir autorización ni motivo. La eliminación se registra igual, con él como autorizante y la marca «privilegio propio»; el servidor comprueba el privilegio en la sesión.
> 4. **Quién autoriza.** Autoriza a otros el ADMIN de la empresa (nunca el SUPER) o quien tenga «Punto de venta · Autorizar». `eliminarrenglon` solo exime a su titular. `POST /api/pos/autorizar` queda como verificación previa del diálogo y usa la misma regla del validador común.
> 5. **Descartar la venta en curso** con renglones exige la misma regla y deja una línea en `audit.Bitacora` (cajero, caja, renglones, importe y autorizante).
> 6. **Límite declarado.** El servidor valida las eliminaciones que la venta declara. Un diario de escaneo en el servidor queda fuera de alcance. Las ventas en espera, si se construyen, no guardarán contraseñas.
>
> **Decidido, no implementado:** en `feature/modelo-ng` (`ce33b2a8`), `POST /api/pos/autorizar` devuelve verdadero o falso y `VentaPos` no lleva eliminaciones.

---

## Hoja de firma

**Recomendación:** marcar **1a, 2i y 3 «Sí, en la misma tanda»**.
- Esfuerzo total: unas 0,5 a 0,7 sp [I, ±40 %].
- Va después de DL-22 y antes del corte de mediados de diciembre.
- Cumple ADR-68 al pie de la letra y reutiliza el validador y el patrón de la devolución del POS.

| Casilla | Opciones | Firma |
|---|---|---|
| **1. Eliminación de renglones (SC08-01)** | ☐ **a) La venta lleva sus eliminaciones; el servidor las valida y las guarda como `ELIMINA_RENGLON`** (recomendada, 0,35-0,5 sp) · ☐ b) Ficha de un solo uso (0,6-0,9 sp) · ☐ c) Solo la bitácora al autorizar (0,1-0,15 sp) · ☐ d) Ninguna: acepto el riesgo | |
| **1-bis. Privilegio propio** | ☐ **Se registra igual, sin motivo** (recomendada) · ☐ No se registra | |
| **2. Quién autoriza (SC08-03)** | ☐ **i) ADMIN o «Punto de venta · Autorizar»; `eliminarrenglon` solo exime** (recomendada) · ☐ ii) ADMIN o `eliminarrenglon`, como propone el auditor | |
| **3. Descartar la venta en curso** | ☐ **Sí, en la misma tanda** (recomendada, +0,1-0,15 sp) · ☐ En otra etapa · ☐ No | |

**Si se firma:** B registra la precisión del punto 5 en ADR-68 (en `master`) y **C** la construye (encargo del propietario del 2026-10-16, aviso `A-a-B/2026-10-16-delegacion-a-c`) en una rama `c/` sobre el #49 o tras su unión. **Si se rechaza:** P-11 sigue abierto y R-6 queda en residual Medio, aceptado.

---

### Cierre
- Estado: Completado (decisión preparada; Pendiente de firma)
- Artefactos: `GPOS-NG-Equipos/traspasos/A/precision-adr68-eliminar-renglones-2026-10-16.md`
- Supuestos:
  - Los costos son estimaciones, sin medición.
  - El riesgo de la llamada directa a la API es una inferencia.
  - No verifiqué si `EditorLineas` deja bajar la cantidad de un renglón ya escaneado (con `CambiarCantidad`); si lo deja, es una eliminación parcial sin autorización.
- Decisiones candidatas a ADR: la precisión de ADR-68 del punto 5 (no hace falta un ADR nuevo).
- Entregas a otros agentes:
  - B → registrar la precisión en ADR-68 si se firma.
  - Desarrolladores del núcleo de A → construir 1a, 2i y 3, con pruebas.
  - arquitecto-datos → la forma de `ArticuloId` y `Cantidad` (columnas o tabla hija).
  - auditor-seguridad → revisar la construcción.
- Próximo paso recomendado: firma del propietario de las casillas 1, 1-bis, 2 y 3.
