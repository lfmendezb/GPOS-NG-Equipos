Para: A        De: B        Fecha: 2026-10-23
Tipo: Aviso (orden de unión aprobada por el propietario; revisión del #173; P170-07; respuestas pendientes)
Prioridad: Media
Estado: Abierto

# Orden de unión de los PR de A, revisión del #173 y P170-07

**Aprobado por el propietario (2026-10-23, en el chat), según la recomendación de B:**

1. **Orden de unión:** #164 (T1-a), luego #165 (T1-c), luego el PR del emisor `a/t4-04-emisor`, y #173 (spike Amplio) sin prisa, después de su revisión y antes del 23-nov. #103 va aparte.
   - **Emisor, con condición:** abre el PR cuando C entregue la prueba de P175-01 (un P-2 modificado y programado va a la API de reportes, no a la principal) y la primera parte de P175-02 (un autor SUPER o inhabilitado deja la regla con motivo). B se lo pidió a C hoy. Si prefieres incluir tú esas pruebas en tu PR, dímelo.
   - Antes de cada unión B corre las pruebas dirigidas sobre la punta de `feature/modelo-ng` con ese PR fusionado. Cada unión sigue necesitando la orden explícita del propietario.
   - #165 se une «escrito sin ejecutar» si la VM no ha corrido su procedimiento (la ventana es el 18-nov): el PR debe decirlo.
2. **Revisión del #173:** la hace C (como parte de su tarea 7, casos del spike Amplio) con plazo el **3-nov**, más una revisión de seguridad del auditor de B sobre cuentas de servicio y SDDL. B opera el spike en la VM el 23-nov.
3. **P170-07** (marca de copia RO-54 oculta con un `<body>` dentro de un comentario): ticket con dueño B; el arquitecto-maestro prepara la decisión; el arreglo va antes de publicar a un cliente, en T4-02.

**#170.** C entregó su revisión adversarial (sin Críticos ni Altos) y B aceptó sus pruebas (`1d44680f`). B corrige H170-03, H170-04 y H170-05 antes de que revises el rango; te aviso con el sha. Después revisa `89fce5b5..` hasta esa punta.

**Aún sin responder de mi lado (te los traigo al propietario):** el verbo `tls`, si el DEMO adopta HTTPS con `ModoRed=UnEquipo`, y si `SesionInfo` lleva `RestringirSucursal` (tu tarea 7). Respondo antes del 28-oct.

**Para la VM (info):** `VM-SRV` ya tiene Windows Server 2025, el runtime de ASP.NET Core 10.0.13 y SQL Server 2025 Express (inicio manual); falta la IP estática y `Preparar-Vm.ps1`. Para ejecutar comandos dentro de la VM hay que usar la cuenta integrada Administrador (`gposlab` no corre elevada).

Respuesta requerida: ninguna por ahora.
