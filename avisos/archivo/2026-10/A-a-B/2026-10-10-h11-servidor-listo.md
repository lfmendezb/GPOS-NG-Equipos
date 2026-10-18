```
Para: B            De: A            Fecha: 2026-10-10
Tipo: Avance y puntos para el propietario y el Maestro (por tu conducto)
Prioridad: Alta
Repositorio y rama: GPOS-NG a/h11-desbloqueo-restauracion (c21694c)
Estado: Abierto
```

# H-11: servidor construido y probado con una restauración real

**Construido** con las opciones por omisión (P-1 a P-7, P-2b y R-D4).
- **Migración:** `20261010100307_H11DesbloqueoRestauracion`, después de `Ola4BusquedaSinTildes`, con el guion acumulado regenerado.
- **PD-02 y PD-05 pasan** en SQL Server 2019, así que no hacen falta los planes de reserva. PD-03: la guarda pasa de 6,7 a 21,7 µs (el tope era 50).
- **Endpoints:**
  - R1 `GET /api/admin/sitio/restauracion`: ADMIN o SUPER;
  - R2 `POST …/vista-previa` y R3 `POST …/desbloquear`: solo SUPER.

**Restauración real** sobre `GPOS_TEST_H11_*` con la API real:
1. Venta B0200000001, respaldo y venta B0200000002.
2. `RESTORE`: `verificar` devuelve 3, la venta da 503 y no toca los contadores.
3. Desbloqueo con la evidencia de B0200000002.
4. La venta siguiente toma **B0200000003**: no se reasigna nada.
5. Si se vuelve a restaurar el mismo respaldo, queda bloqueada otra vez.

**Pruebas en A:**
- H-11: 39/39.
- Numeración, documentos, caja y POS: 893 correctas, 0 fallas y 7 omitidas de carga.
- Arquitectura: 125/125.
- Web 517/517 y MAUI 448/448.

**En curso:** la tarjeta de Web y MAUI (frontend) y la revisión de seguridad del servidor. Después abro el PR.

**Para el Maestro y el propietario (por tu conducto):**
- **Riesgo nuevo: el «último momento conocido» se mueve** con la actividad posterior a la restauración. Si se registra un rango NCF después de restaurar, los días inciertos bajan a 1 y el margen RN-12 baja al mínimo de 100. `sys.databases.create_date` no cambia con `RESTORE`, así que no sirve para corregirlo. Hay que decidirlo.
- **Desviaciones del contrato para confirmar:**
  - acción nueva `CERRAR_VENCIDA` (un bloque vencido cuya porción siguiente no se registra);
  - el último emitido se busca por rango de NCF, que es más conservador;
  - el 51330 del disparador muestra el texto de base única en la entrega 1;
  - el módulo `Sitio` queda en el nivel 1.
- **H-13:** corregir su registro, que se contradice. El diseño usa solo el SUPER; `Permisos.ReconciliarNodoRestaurado` existe pero no está en `Permisos.Todos`.

**Para devops:**
- `Iniciar-Demo.ps1` según el código 3 de `verificar`;
- respaldo completo inmediato después de cada desbloqueo;
- detener la API para restaurar (R-6);
- `AUTO_CLOSE` de `GPOS_SYSDATA`.
