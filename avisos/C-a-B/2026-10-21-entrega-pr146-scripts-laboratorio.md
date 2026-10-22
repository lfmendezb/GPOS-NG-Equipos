```
Para: B        De: C        Fecha: 2026-10-21
Tipo: Entrega (tarea 6: guiones del laboratorio de ADR-90 con VBoxManage)
Prioridad: Media
Repositorio y rama: GPOS-NG c/laboratorio-adr090-scripts, PR #146 sobre feature/modelo-ng (e3e729c1)
Estado: Abierto
```

# Entrega: PR #146, guiones del anfitrión del laboratorio de ADR-90 para `LFMB`

[#146](https://github.com/lfmendezb/GPOS-NG/pull/146), respuesta a `B-a-C/2026-10-21-asignaciones-scripts-laboratorio-y-plan-e1.md` (tarea 6). Antes del 1-nov.

**Qué trae** (`tests/laboratorio-adr090/`, con `LEEME.md`): los seis guiones mínimos del encargo y tres más.
1. `Preparar-Anfitrion.ps1`: comprueba que el equipo es exactamente `LFMB`, la firma y la versión 7.2.22 de VirtualBox, el espacio en `M:` y la memoria libre real por bloque.
2. `Crear-VmLaboratorio.ps1` y `Cerrar-Preparacion.ps1`: crean las VM y cierran su preparación (sin salida a Internet antes de `base`).
3. `Puntos-Control.ps1`: puntos de control por UUID.
4. `Ajustar-Reloj.ps1`: reloj de las VM.
5. `Recoger-Evidencia.ps1`: evidencia con redacción LS-11.
6. `Limpiar-Anfitrion.ps1`: limpieza por marcador.

Los tres de más son `Leer-Credencial.ps1`, `Probar-Redaccion.ps1` y el común `herramientas/Comun-Laboratorio.ps1`. Las imágenes y sus huellas son parámetros; la de Ubuntu 24.04.5 va en el ejemplo del LEEME.

**Honestidad: qué se probó.**
- **Ningún comando `VBoxManage` se ejecutó** (OSHIN-LEGION no tiene VirtualBox). Cada comando lleva [V] (sintaxis del manual 7.2) o [I] (inferencia).
- Los 10 `.ps1` se analizan sin errores en PS 5.1 y 7.
- La redacción pasa 42/42.
- Los 8 guiones que operan se detienen aquí sin tocar nada.

**Correcciones a mi rediseño tras leer el manual de la 7.2:**
- La hora se apaga con la llave `GetHostTimeDisabled`, no con `guestproperty`.
- Existe `--firmware-system-time-offset` para adelantar el reloj de la VM.
- La clave se pasa con `--user-password-file` y `--admin-password-file`.
- `createvm` pide `--platform-architecture=x86`.

**Revisión de seguridad** (auditor de C): Aprobado con observaciones, sin Críticos ni Altos, con 4 Medios y 11 Bajos (SL-01 a SL-15). Todos se atendieron en `b9ca742d`; el informe está en `traspasos/C/2026-10-21-revision-seguridad-scripts-laboratorio.md`.

**Lo que queda para B:**
- Confirmar los 9 puntos [I] del LEEME en `LFMB`. El más importante: en la primera ejecución con `-Desatendida`, comprobar que la clave no sale en la consola; si sale, rehacer la VM.
- Limpiar los restos de la clave dentro de la VM antes de `base` (SL-07; lista en el LEEME).
- Agregar el `.gitignore` de LS-11.
- Devolverme lo que falle.

Nada se une sin orden expresa del propietario. Sigo con la tarea 5 (PR de documentos P126, 3-nov).
