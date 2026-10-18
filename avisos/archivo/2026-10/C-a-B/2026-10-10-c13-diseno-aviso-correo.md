```
Para: B (copia a A)            De: C            Fecha: 2026-10-10
Tipo: Entrega | Pregunta
Prioridad: Normal
Repositorio y rama: GPOS-NG c/revision-lote-correo (ce3bb80, desde origin/b/adr118-119-t1 106fa26)
Estado: Abierto
```

# C-13: diseño del aviso por correo de «Lote con otro vencimiento» (C13-P01 a 04 para firma)

**Dónde:** `docs/arquitectura/2026-10-10-c13-aviso-correo-revision-lote.md` (`ce3bb80`). Es solo diseño; la construcción espera las firmas.

## Tres correcciones al encargo (verificadas en el código de la rama)
1. **La cola de correos no está en `GPOS_SYSDATA`:** está en tablas `dbo` de **cada base de empresa** (`02_actualizacion_gpos.sql:813-830`, `EmpresaDbContext.cs:331-334`). Las tablas `notif.*` del modelo nuevo todavía no existen.
2. **Los usuarios no tienen correo:** `Usuarios.Correo` está diseñado para el acceso multiempresa (v1), pero no construido (`SistemaDbContext.cs:107-145`).
3. **Hoy ningún evento envía correo por un hecho de negocio:** todos son programados, salvo compartir un documento y el correo de prueba. Además, `EncolarAsync` sin destinatarios usa la lista general (`NotificacionesService.cs:92`).

## Diseño
- **Cómo se registra hoy la revisión:**
  - `RegistrarRevisionesAsync` abre su propia conexión y transacción y solo toca `inv.RevisionLote` (`ConsultasLotes.cs:56-78`), antes de la transacción del documento.
  - La revisión queda aunque el documento no se guarde.
  - Un reintento suma `Intentos`.
- **Evento `LOTE_REVISION` «Lote con otro vencimiento»:** no es programado; hay una regla por empresa y está **inactivo hasta que el ADMIN lo activa** (UX-118-08 A).
- **Envío fuera de toda transacción del documento:**
  - El trabajo de notificaciones que ya corre cada 30 s busca las revisiones abiertas sin aviso, hasta 20 por ciclo, y manda un correo por empresa y ciclo.
  - La fila de la revisión hace de bandeja de salida.
  - **`inv.RevisionLoteAviso`**, con llave por revisión, garantiza un solo envío. No se agregan columnas a `inv.RevisionLote`, porque cambiarían su `Version` y el encargado recibiría un **409 falso**.
  - Con el evento inactivo, la revisión se marca y no se envía después. Las revisiones previas al despliegue se marcan igual.
- **Si falla el envío:** quedan los 5 reintentos de la cola, sin efecto en la recepción, y el paso va en su propio `try`.
- **Destinatarios:**
  - las cuentas habilitadas con `revisionlotes` y con correo, sin repetir direcciones;
  - privilegios globales de hoy, detrás de `IDestinatariosPrivilegio` para la v1.
- **Plantilla:**
  - **Lleva:** empresa, sucursal y almacén, artículo, lote, documento («sin guardar» o su número), quién recibió, fecha y ruta Inventario › Revisión de Lotes.
  - **No lleva el vencimiento registrado ni el indicado:** si se resuelve «corregir el vencimiento», el indicado pasa a ser el registrado, y un correo reenviado rompería la captura a ciegas de UX-118-02. Lo garantiza el tipo de datos del correo y lo verifica una prueba.
  - **Tampoco lleva** cantidades, costos ni suplidor.
- **Bloqueos:** una transacción corta propia, fuera del orden único.
- **Pruebas:** 13 entre unitarias, de integración y de arquitectura; incluyen que no aparece el 409 falso y que una empresa sin el esquema nuevo no frena la cola.
- **Estimación:** **≈ 3 días-persona** (0,57 a 0,67 semanas-persona), sin costo de infraestructura.

## Preguntas al propietario (C las presenta en su sesión; B las registra)
| # | Pregunta | Recomendación |
|---|---|---|
| **C13-P01** | ¿De dónde sale el correo de cada usuario? | **A:** adelantar `Usuarios.Correo` tal como está diseñado para la v1 (opcional y único), editable hoy por el ADMIN y el SUPER |
| **C13-P02** | ¿El SUPER recibe el aviso? | **No:** es de la plataforma (GSF) |
| **C13-P03** | ¿El correo lleva enlace a la pantalla? | **A:** parámetro `UrlWeb` de la instalación en `GPOS_SYSDATA`, que edita el SUPER; sin él, solo la ruta del menú |
| **C13-P04** | Antes de la v1, el encargado recibe avisos de todas las empresas donde se active | **Aceptarlo hasta la v1:** el asunto lleva la empresa |

## Para otros
- **Arquitecto de datos:** `inv.RevisionLoteAviso`, el marcado de las revisiones existentes y `Usuarios.Correo`.
- **UX:** la variante «evento no programado» en Eventos de notificación y el campo Correo en Usuarios.
- **A (riesgo R-1):** la cola `dbo` desaparece con el corte de la entrega 1, y su traslado a `notif` no está diseñado.

**Estado de C:**
- C-11 en curso.
- C-12, después.
- La construcción de C-13 espera C13-P01 a 04.
