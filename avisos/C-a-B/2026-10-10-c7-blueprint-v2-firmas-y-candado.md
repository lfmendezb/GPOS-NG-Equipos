```
Para: B            De: C            Fecha: 2026-10-10
Tipo: Entrega | Pregunta
Prioridad: Normal
Repositorio y rama: GPOS-NG c/adr81-fase-a-diseno (929f44e)
Estado: Abierto
```

# C-7: blueprint de la fase A de ADR-81, versión 2, con las firmas y el candado de restauración

Responde a `B-a-C/2026-10-10-firmas-c5-c7.md`. Solo es diseño: no se programó, no se compiló y no se ejecutó SQL.

**Dónde:** rama `c/adr81-fase-a-diseno`, commit `929f44e`:
- `docs/arquitectura/2026-10-10-adr81-fase-a-blueprint.md`
- `docs/decisiones/2026-10-10-preguntas-adr81-fase-a.md`

En el documento de preguntas, P-81A-01 a 10 y las firmas de hoy quedan marcadas como firmadas, con dónde se aplica cada una.

## Qué se incorporó
- **§7.2:** lo sustituye el SQL corregido de la revisión de datos (D81-01 a 12): tablas fuera de `SistemaDbContext`, con acceso por SQL escrito a mano. Se agrega la columna `CodigosRevividos` (P-D81-01 a).
- **Bloque B de §7.2, no probado: lo debe validar el arquitecto de datos.**
  - tabla de una fila `RestauracionSistema`;
  - vista que calcula el candado y falla cerrada (activo si el fork es nulo o distinto del registrado);
  - procedimientos `ReconciliarRestauracionSistema` y `LiberarCandadoRestauracion` con `EXECUTE AS OWNER`;
  - errores 52003 a 52007.
- **CR-01 con D81-07 (§6.6, §8.8):**
  - **Detección:** al arrancar, cada 30 s y en la lectura de cada petición (caché de 15 s).
  - **Reconciliación, una sola vez por restauración:** sello nuevo, cierre de todas las sesiones, códigos de respaldo marcados como revividos, evento `SISTEMA_RESTAURADO` y `UltimoPaso` adelantado según la hora de la base, nunca la del reloj protegido, para no reabrir R-01.
  - **Mientras dure el candado:** se rechaza toda escritura salvo una lista permitida (inicio de sesión, factor, clave, códigos, teléfono, restablecer o desbloquear, resolver el reloj, liberar y consultas). Una ruta sin marca queda bloqueada.
  - **Liberación:** pide factor, autenticación reciente y motivo, y comprueba que no hubo otra restauración desde la consulta.
  - **Orden:** primero `GPOS_SYSDATA`, después cada base de empresa con su desbloqueo de H-11.
- **El SUPER nunca queda sin salida** con el candado activo, siempre que haya al menos un SUPER (el arranque recrea `GSF`) y alguien tenga la consola del servidor (vía b). Se revisaron doce casos (S1 a S12 de §6.6): contraseña o teléfono cambiados después del respaldo, base restaurada en otro equipo sin el anillo, factor bloqueado, reloj adelantado, sesión vencida y versión sin MAUI. La vía b no pasa por la API: es la salida de último recurso y no se puede quitar.
- **Contratos (§5):**
  - el 409 trae los códigos y los avisos (`AvisosEntrada`, UX-81A-01);
  - volver a entrar durante un alta devuelve el mismo secreto (UX-81A-02);
  - `/clave` con `cambiar_clave = 1` no pide autenticación reciente (UX-81A-08);
  - un código revivido pide además la contraseña (`CLAVE_REQUERIDA`);
  - D-01 a D-07 entran al contrato;
  - `SesionInfo` gana `SistemaRestaurado` y `MinutosInactividad`;
  - rutas nuevas `GET` y `POST /api/super/sistema/restauracion[/liberar]`.
- **Otras secciones:** riesgos R-13 a R-18 (§11); pruebas PF-08 y PF-31 a PF-40, con una restauración real de `GPOS_SYSDATA` y un inventario de rutas (§12); franja «Sistema restaurado» y pantalla «Restauración del Sistema» (§15).

## Estimación (±30 %)
| | Antes | Ahora |
|---|---|---|
| Fase A completa | 6,75 sp | **≈ 8,55 sp** (de 6,0 a 11,1) |
| Costo | USD 10.100 a 13.500 | **USD 12.800 a 17.100**; infraestructura USD 0 |
| Calendario | ≈ 1,5 semanas | **≈ 1,9 semanas** de un desarrollador |
| Fase A mínima | ≈ 5,9 sp | **≈ 7,6 sp** |

- **De dónde salen los +1,8 sp:**
  - candado y restauración de `GPOS_SYSDATA` (tanda nueva T5b, que no se puede recortar): +0,9;
  - correcciones de datos: +0,15;
  - UX-81A y D-01 a D-07: +0,55;
  - pruebas: +0,2.
- **T5b baja a unos 0,75 sp** si A construye primero **un solo middleware** para los dos candados (§8.8.6).

## Preguntas nuevas al propietario
| # | Pregunta | Recomendación |
|---|---|---|
| **P-81A-11** | Con `GPOS_SYSDATA` restaurada, ¿quién entra? | (a) Solo el SUPER, sin escrituras de negocio en ninguna base hasta liberar, porque al restaurar reviven cuentas y permisos ya quitados. **Conviene firmarla antes de T4 y T5b** |
| P-81A-12 | La marca P-7 vive en `GPOS_SYSDATA` y baja si esta se restaura, lo que reabre el riesgo de NCF duplicados | (a) Recomponerla al liberar con los desbloqueos registrados en las bases de empresa, y respaldar `GPOS_SYSDATA` después de cada desbloqueo (A, ≈ 0,1 sp) |
| P-81A-13 | Los dispositivos revocados después del respaldo vuelven a estar activos | (a) La pantalla de liberación los lista y la guía pide revisarlos; no se reemparejan todos |

## Para B y A
- **Arquitecto de datos:** validar y ejecutar el bloque B y `CodigosRevividos` con una restauración real. C puede hacerlo si B lo encarga.
- **Equipo A (H-11):**
  - un solo middleware y una sola lista de marcas para los dos candados;
  - marcar R3 como acción sensible y R2 como consulta;
  - respetar el orden de liberación.
- **R-16:** entre la unión de H-11 y la de la fase A, `GPOS_SYSDATA` no tiene candado. Hoy solo afecta a desarrollo y al DEMO; se puede adelantar la parte que no depende del factor.
- **Supuestos sin verificar:**
  - que `sys.database_recovery_status` sea legible con privilegio mínimo (RG-14);
  - que el valor del nivel sea `'SUPER'`;
  - que el fork de `GPOS_SYSDATA` se comporte como el de las bases de empresa.

## Estado de C
- C-5, C-6 y C-7 están entregados, con los ajustes de las firmas de hoy.
- C-2 espera el PR de H-11.
- C queda sin agentes activos.
