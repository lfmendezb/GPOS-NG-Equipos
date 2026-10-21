```
Para: C        De: B        Fecha: 2026-10-21
Tipo: Encargo (dos tareas nuevas, se suman a la cola del 2026-10-21)
Prioridad: Media
Repositorio y rama: GPOS-NG `feature/modelo-ng`; PR #134 (ADR-93)
Estado: Abierto
```

# Dos tareas nuevas para C

Reglas de siempre: filtros por clase, sin suites completas ni cargas SQL en OSHIN-LEGION, commit y push frecuentes, nada se une sin orden expresa del propietario. Sus tareas con fecha siguen igual: guarda de lo transitorio (27-oct), revisión de pruebas de #130 y #122 (28-oct), revisión crítica del #127 (29-oct) y PR de documentos (3-nov).

## Tarea 6: scripts del laboratorio con `VBoxManage`
`tests/laboratorio-adr090/` **no existe en ninguna rama**: hoy el laboratorio es solo diseño. Escriban los scripts (sin ejecutarlos: OSHIN-LEGION no tiene VirtualBox) para que B los ejecute en `LFMB`.
- **Anfitrión:** `LFMB`, Windows 11 Home, VirtualBox **7.2.22** (no la 7.0 ni la 7.1 que su rediseño recomendaba: revisen que cada comando `VBoxManage` de su rediseño exista y se comporte igual en la 7.2). Las VM en `M:\VM`; las imágenes en `M:\VM\imagenes`.
- **Scripts mínimos:** (1) `Preparar-Anfitrion.ps1`: comprueba positivamente que el nombre sea `LFMB`, la versión de VirtualBox, el espacio libre en `M:` y la memoria libre real antes de cada ejecución; (2) creación de `VM-SRV`, `VM-PUESTO` y `VM-LNX` (memoria, discos, red interna `GPOS-LAB` sin salida a Internet durante los casos, instalación desatendida si `VBoxManage unattended` lo permite con esas imágenes); (3) puntos de control (`snapshot`) base y por caso; (4) reloj de las VM (`guestproperty` o la alternativa que corresponda a VirtualBox 7.2, sin sincronizar con el anfitrión); (5) recolección de evidencia con redacción de secretos; (6) limpieza por marcador.
- **Imágenes:** Ubuntu Server 24.04.5 ya está descargada y verificada (`ubuntu-24.04.5-live-server-amd64.iso`, SHA-256 `97f3d7ffb032c3eb3b23d2c8be9cc76e60c2c1f2c0146ba5ba9fe01cafae0fd8`, 4 080 486 400 bytes). Las de Windows Server 2025 y Windows 11 Enterprise las descarga el propietario del Centro de Evaluación de Microsoft; B les pasa los nombres y las huellas cuando lleguen. **Escriban los scripts con los nombres de archivo como parámetros.**
- **Honestidad:** marquen en el script y en el informe qué se probó (nada) y qué es inferencia de la documentación de VirtualBox. B prueba en `LFMB` y les devuelve lo que falle.
- **Plazo: 2026-11-01.** Entrega: PR sobre `feature/modelo-ng` con los scripts y un LEEME corto.

## Tarea 7: plan de pruebas de E-1 del ADR-93 (tarjetas sin foto)
ADR-93 está registrado en el PR #134 (rama `b/adr93-tarjetas-foto`: `docs/adr/ADR-093.md`; hoja `docs/decisiones/2026-10-21-hoja-firma-tarjetas-articulos.md`). Plan de pruebas de la pieza E-1, **sin foto**:
- Listado paginado («Página N de M», tamaños 12, 24, 48 y 96, orden fijo por descripción e Id, total correcto, filtros actuales).
- Alerta de existencia baja por almacén y rombos (la fórmula de TA-04: un rombo por cada 25 % del reorden general); **TA-P05 firmada: un almacén con mínimo y sin movimientos sí alerta**; **TA-P08: un usuario restringido a su sucursal ve solo los almacenes de su sucursal; la central ve todos.**
- Que ningún campo nuevo sea un `DatoCosto` (la tarjeta es igual para quien no ve costos) y que `ArticuloFila` y `GET /api/maestros/articulos` queden como están.
- Preferencia por usuario y empresa (vista Tabla por omisión, nivel de precio 1 por omisión, caída a Precio 1 si el nivel guardado ya no existe).
- Color de categoría (`#RRGGBB`, blanco por omisión) y la píldora con puntos suspensivos.
- Marquen qué pruebas necesitan SQL y cuáles son de texto o de reflexión, y las que dependen de decisiones aún abiertas.
- **Plazo: 2026-11-05.** Entrega: `traspasos/C/` y aviso en `C-a-B/`.

Respuesta requerida: acuse con fechas.
