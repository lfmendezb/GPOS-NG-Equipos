# Hoja de comandos · complemento AdmCloud v2 (`GSF.Sync.AdmCloud`)

Fuente: `C:\Users\lfmen\source\repos\IGpostAC\v2\README.md` (rama `master`, último commit `bb87131`). El ejecutable se llama **`IGpostAC.exe`** a propósito, para que GPOS y las tareas programadas de v1 sigan funcionando sin cambios.

## 1. Instalación y configuración (una sola vez)

| Qué | Comando |
|---|---|
| Publicar (con .NET instalado) | `dotnet publish v2\GSF.Sync.AdmCloud.Cli -c Release -o C:\GSF\SyncAdmCloud` |
| Publicar autocontenido | `dotnet publish v2\GSF.Sync.AdmCloud.Cli -c Release -r win-x64 --self-contained -o C:\GSF\SyncAdmCloud` |
| Proteger la carpeta de datos | `icacls C:\GSF\SyncAdmCloud\data /inheritance:r` y dar permiso solo a la cuenta del servicio y a administradores |
| Conexión con usuario SQL (la contraseña se pide oculta) | `.\IGpostAC.exe config connection set --server "SRV01\SQLEXPRESS" --database "POS_CLIENTE" --user "gsf"` |
| Conexión con autenticación de Windows | `.\IGpostAC.exe config connection set --server "SRV01\SQLEXPRESS" --database "POS_CLIENTE" --integrated` |
| Ver / probar / borrar la conexión | `config connection show` · `config connection test` · `config connection clear` |
| Instalar objetos de diagnóstico (repetir tras cada actualización) | `config schema install` |
| Estado del esquema | `config schema status` |

`config connection set` comprueba que exista `Api_AdmCloud_Settings` con datos antes de guardar. `config schema install` crea `Api_AdmCloud_SyncEstado`, dos vistas y la columna `ItemSync`.

## 2. Sincronización (`sync`)

| Comando | Qué sincroniza |
|---|---|
| `sync all` | Todo lo habilitado en `Api_AdmCloud_Settings` (no crea artículos) |
| `sync customers` | Maestra de clientes |
| `sync quotes` | Cotizaciones |
| `sync salesorders` | Pedidos de venta |
| `sync invoices` | Facturas de crédito y de contado |
| `sync returns` | Devoluciones y notas de crédito |
| `sync receipts` | Recibos de ingreso |
| `sync items` | Artículos simples creados en el POS (**único** camino que crea artículos) |

- Todos aceptan el número del documento: `sync invoices A-001234`, `sync all A-001234`, `sync items 721296`.
- Al nombrar un documento no se aplica el filtro de pendientes. Si ya está sincronizado con `Ac_ID`, no lo reenvía; si está marcado sin `Ac_ID`, consulta a AdmCloud antes de reenviar.
- Opciones: `--no-wait` (encola y termina) · `--timeout <seg>` (600 por omisión; `0` sin límite).

## 3. Invocación desde GPOS (sin cambios respecto de v1)

| Invocación | Efecto |
|---|---|
| `IGpostAC.exe` | Sincroniza todo lo habilitado |
| `IGpostAC.exe "{guid};{tipoNcf}"` | Firma electrónicamente ese documento |
| `sign <doc> <ncf>` | Lo mismo, desde la consola |
| `service` | Ejecuta la sincronización de forma continua |

## 4. Cola (`queue`)

| Comando | Para qué |
|---|---|
| `queue stats` | Resumen del estado de la cola |
| `queue list` (`--state`, `--type`, `--limit`) | Listar trabajos, p. ej. `queue list --state DeadLetter` |
| `queue show <doc>` | Estado de un documento; también el error de un artículo |
| `queue retry <doc>` | Devolver a la cola un documento que requirió intervención |
| `queue verify` | Resolver los que esperan confirmación |
| `queue purge --older-than <días> [--apply]` | Borrar trabajos terminados (sin `--apply` solo mide) |

## 5. Reconciliación y migración desde v1

| Comando | Para qué |
|---|---|
| `reconcile` | Mide, sin modificar, los documentos que v1 «enterró» (usa `Reconciliation:FromDate` de `appsettings.json`) |
| `reconcile --from aaaa-mm-dd` | Igual, con otra fecha de corte (tiene prioridad) |
| `reconcile --apply` | Recupera: consulta a AdmCloud antes de reenviar cada documento |

Sin fecha de corte el comando no corre (código `3`). **No ejecutar v1 y v2 a la vez contra la misma base**: v1 anula el token con un `UPDATE` sin `WHERE`.

## 6. Bitácora de auditoría (`audit`)

| Comando | Para qué |
|---|---|
| `audit list` (`--document`, `--since`, `--level`, `--limit`, `--console`, `--pending`) | Ver la bitácora |
| `audit show <n>` | Eventos completos |
| `audit forward` | Copiar ya a SQL Server lo pendiente |
| `audit purge --older-than <días>` o `--before <fecha>` `[--apply]` | Borrar eventos antiguos |

## 7. Verificación inicial recomendada

```powershell
.\IGpostAC.exe config connection test
.\IGpostAC.exe config schema status
.\IGpostAC.exe queue stats
.\IGpostAC.exe sync customers      # primer tipo de documento, y observar
```

## 8. Códigos de salida (los lee GPOS)

| Código | Significado | Acción |
|---|---|---|
| 0 | Correcto | — |
| 1 | Documentos que requieren revisión manual | `queue list --state DeadLetter` |
| 2 | Se agotó la espera | Lo pendiente sigue en cola |
| 3 | Sin cadena de conexión o no se descifra; o `reconcile` sin fecha de corte | `config connection set` / fijar fecha |
| 4 | No conecta a SQL Server o a AdmCloud | `config connection test` |
| 5 | AdmCloud rechazó las credenciales | Revisar `Api_AdmCloud_Settings` |
| 10 | Error no previsto | Ver la salida |

## 9. Consultas SQL de diagnóstico (desde SSMS)

```sql
SELECT * FROM Api_AdmCloud_SyncFacturas WHERE Documento = 'A-001234';  -- una factura
SELECT * FROM Api_AdmCloud_SyncEstado   WHERE DocumentoId = 'A-001234'; -- cualquier documento o maestro
SELECT * FROM Api_AdmCloud_SyncRevisar  ORDER BY UltimoCambio DESC;     -- todo lo que requiere revisión
UPDATE Api_AdmCloud_Settings SET ItemSync = 1;  -- lista en la vista de revisión los artículos que no se pueden crear
```

## 10. Qué documento va a qué recurso de AdmCloud

| `Tipo` | `TipoFact` | Recurso |
|---|---|---|
| `FACT` | — | `CreditInvoices` |
| `FACT POS` / `FACT REST` | — | `CashInvoices` |
| `DEVOLUCION` | `FACT POS` o `FACT REST` | `CashReturns` |
| `DEVOLUCION` | `FACT` | `CustomerCreditNotes` |
| `DEVOLUCION` | vacío u otro | Sin ruta: aparece en `Api_AdmCloud_SyncRevisar` |

## 11. Flujo ante un documento en revisión manual por artículo

1. Crear o corregir el artículo (o agregar la unidad a una tabla de unidades en AdmCloud).
2. `.\IGpostAC.exe sync items [código]` si hace falta.
3. `.\IGpostAC.exe queue retry <doc>`.

Los documentos nunca crean artículos; las variantes y los servicios no se crean (quedan `Unsupported` en `Api_AdmCloud_SyncRevisar`).

---

# 12. Parámetros de cada comando

Tomados del código del CLI (`v2\GSF.Sync.AdmCloud.Cli\Commands\*.cs`). `<x>` = argumento posicional; `[ ]` = opcional. Los booleanos (`--apply`, `--json`…) no llevan valor: basta escribirlos.

## sync (all | customers | quotes | salesorders | invoices | returns | receipts | items)
| Parámetro | Tipo | Por omisión | Descripción |
|---|---|---|---|
| `[documento]` | texto | todos los pendientes | Número del documento (o del artículo en `items`) a sincronizar |
| `--no-wait` | bandera | espera | Encola y termina sin esperar |
| `--timeout <seg>` | entero | 600 | Segundos máximos al drenar la cola; `0` = sin límite |

## sign `<documento>` `[tipoNcf]`
| Parámetro | Tipo | Por omisión | Descripción |
|---|---|---|---|
| `<documento>` | texto | — | Identificador del documento en AdmCloud, o el formato heredado `{guid};{tipoNcf}` |
| `[tipoNcf]` | texto | — | Tipo de secuencia fiscal. Con 32 basta la firma; los demás requieren consultar el estado |
| `--wait` | booleano | `true` | Espera a que se complete la firma antes de terminar |

## reconcile
| Parámetro | Tipo | Por omisión | Descripción |
|---|---|---|---|
| `--from aaaa-mm-dd` | fecha | `Reconciliation:FromDate` de `appsettings.json` | Fecha de documento desde la que revisa, inclusive. Sin ella ni la clave, no corre (código 3) |
| `--apply` | bandera | simula | Encola la recuperación; sin ella solo informa el alcance |

## service
Sin parámetros. Drena la cola de forma continua; si otro proceso ya la drena, no arranca un segundo.

## queue
| Subcomando | Parámetros |
|---|---|
| `queue stats` | ninguno |
| `queue list` | `--state <estado>` (filtra) · `--type <tipo>` (filtra) · `--limit <n>` (25 por omisión) |
| `queue show <documento>` | `<documento>`: número, p. ej. `A-001234` |
| `queue retry <documento>` | `<documento>`: número o identificador del trabajo |
| `queue verify` | ninguno |
| `queue purge` | `--older-than <días>` (por omisión `Queue:SucceededRetention`, 30) · `--apply` (sin ella solo simula). Borra solo los ya sincronizados o cancelados; los que requieren revisión nunca |

- **Valores de `--state`:** `Pending`, `Leased`, `InFlight`, `Verifying`, `Succeeded`, `Failed`, `DeadLetter`, `Cancelled`.
- **Valores de `--type`:** `Customer`, `Quote`, `SalesOrder`, `CreditInvoice`, `CashInvoice`, `CashReturn`, `CustomerCreditNote`, `CashReceipt`, `ElectronicSign`, `Reconciliation`, `Item`.

## config connection
| Subcomando | Parámetros |
|---|---|
| `config connection set` | `--value <cadena>` (cadena completa; si se omite, se pide oculta) · `--server <srv>` · `--database <bd>` · `--user <usr>` · `--password <clave>` (con `--user` y sin ella, se pide oculta) · `--integrated` (autenticación de Windows) · `--trust-server-certificate` (certificado autofirmado) · `--no-test` (guarda sin comprobar) |
| `config connection show` | ninguno (no revela la contraseña) |
| `config connection test` | ninguno |
| `config connection clear` | `--yes` (confirma el borrado sin preguntar) |

Recomendación: no usar `--password` ni `--value` en la línea de comandos (queda en el historial); omitirlos para que la pida por consola.

## config schema
| Subcomando | Parámetros |
|---|---|
| `config schema install` | ninguno |
| `config schema status` | ninguno |

## audit
| Subcomando | Parámetros |
|---|---|
| `audit list` | `--document <doc>` · `--job <guid>` (trabajo de la cola) · `--type <tipo>` (p. ej. `CashInvoice`, `Item`) · `--level <nivel>` (mínimo: `Information`, `Warning`, `Error`, `Fatal`) · `--since <fecha>` y `--until <fecha>` (`aaaa-mm-dd` o `"aaaa-mm-dd hh:mm"`, hora local) · `--search <texto>` (mensaje, excepción, propiedades, comando) · `--limit <n>` (50) · `--console` (solo líneas escritas en consola) · `--pending` (solo lo no copiado a `Api_AdmCloud_SyncLog`) · `--detail` (cada evento completo) · `--json` (exportar) |
| `audit show <número>...` | uno o varios números de evento, como los muestra `audit list` |
| `audit forward` | ninguno (copia ya lo pendiente a SQL Server) |
| `audit purge` | `--older-than <días>` · `--before <fecha>` (aaaa-mm-dd, hora local) · `--target all\|local\|sqlserver` (por omisión `all`) · `--apply` (sin ella solo simula) |
