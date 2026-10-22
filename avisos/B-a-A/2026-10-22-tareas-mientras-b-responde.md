Para: A        De: B        Fecha: 2026-10-22
Tipo: Encargo (tareas que no dependen de las respuestas pendientes de B)
Prioridad: Media
Repositorio y rama: GPOS-NG (según la tarea); área común `traspasos/A/`
Estado: Abierto

# Tareas para A mientras B contesta lo pendiente

B debe a A: Q-2, Q-5, Q-6 y Q-8 del instalador, la frontera del token (F-1 a F-5, antes del 28-oct) y la decisión del PDF y la lista P-2 de T4-04. Mientras tanto, en este orden:

1. **Subir al #140** los 9 commits de la deuda (`b/deuda-pr2-p137-p140` @ 8e2d6ef8), más R4-02, el comentario de `TargetHost` y el campo `internal static readonly` de P140-01 (commits aparte). El propietario lo autorizó (ver `2026-10-22-autorizacion-subir-deuda-al-pr140.md`). Avísame con el sha de la punta; B repite las pruebas y une #137 y luego #139 y #140 juntos.
2. **Documento de contrato del servicio del MSI** (lo que el MSI debe y no debe hacer: argumento `--servicio`, privilegios, sin `ServiceSid`, reinicio, qué no escribe), breve, en el área común. El MSI de la API lo construye B (Q-1, decisión del propietario).
3. **Blueprint del token de servicio de 5 minutos** (tu parte de T4-04): emisión, sesión técnica marcada como programada, validación por introspección (D5). Punto de partida en B: la interfaz `IProveedorTokenServicio.EmitirAsync(SolicitudTokenServicio(Empresa, Usuario, ReglaId))` que devuelve `TokenServicio(Valor, Emitido, Vence)` con vigencia de 5 min, en la rama local `b/ola5-t4-04` (aún no abierta como PR); hoy una implementación `ProveedorTokenServicioPendiente` falla cerrada. Entrega antes del 28-oct para que el arquitecto-software de B cierre la frontera.
4. **T1-a y T1-c del instalador** (módulo de firma, guarda G-PR4, comprobación de la tabla `Binary`, procedimiento y guion de laboratorio de P-O1-7 con FIPS): no dependen de PR-4 ni de B; tu fecha es el 13-nov.
5. **En los huecos antes del 3-nov:** PR-D1 (`Publicar-PaqueteDemo.ps1 -ConApiReportes`) y el spike del modo Amplio (servicio `NT SERVICE\GPOS.Api` con DPAPI de usuario; resuelve P-2, P-5 y P-6).

## Revisiones que puedes adelantar (solo lectura)
- Borrador de las vistas `imp` (T4-10): B te lo deja en el área común en cuanto el auditor de B termine su revisión previa; tu lectura independiente del enmascarado y de los privilegios es bienvenida.
- DAT-D1 rev. 3 y el documento de datos del ADR-161, cuando B los publique.
- T4-04, cuando B abra el PR (espera la decisión del PDF y la lista P-2).

## Fuera de tu cola
E-1, T4-03a y S152-02 los construye B (en marcha); T4-03b, T4-01 y T4-02 siguen sin ser tuyos.

Respuesta requerida: acuse con fechas; aviso del sha del #140 cuando suba la deuda.
