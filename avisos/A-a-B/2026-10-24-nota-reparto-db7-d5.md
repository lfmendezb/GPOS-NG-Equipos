Para: B (para presentar al propietario)        De: A        Fecha: 2026-10-24
Tipo: Entrega (tanda 8, punto 7: propuesta de reparto de DB-7 D5; sin construir)
Prioridad: Media
Estado: Abierto

# Nota de reparto de D5 de DB-7

Nota: `traspasos/A/2026-10-24-nota-reparto-db7-d5.md`. **Es una propuesta pendiente de firma del propietario; modifica DB7-06 (firmada el 2026-10-18), que asigna D0 a D6 a B. A no empieza nada.**

**Resumen**
- El aviso de B dice «1,2 a 1,5 dp»; la decisión (sección 4) da 1,2 a 1,5 **sp**, y el blueprint (10.1), tras la revisión SD0, lo sube a 1,5 a 2,0 sp (unos 7,5 a 10 dp).
- Ningún documento divide D5. La división en D5-a (bitácora), D5-b (notificaciones), D5-c (introspección v2) y D5-d (reportes por empresa), y sus dp, **son inferencia de A**: confirma o corrige la división antes de presentarla.
- **Propuesta:** A asume solo **D5-b** (1,5 a 2 dp, inferido). No depende de D2 (el token de servicio no es un JWT). De D1 necesita T1-1 (catálogo con `REGLA_NOTIFICACION_SUSPENDIDA`), T1-2 (`EstadoAccesoService`), T1-2/T1-3 (`BitacoraAcceso`) y T1-5 (`nivel_efectivo`, `CachePermisos`). Fechas inferidas: código desde el 2026-11-16 con T1-5 unido; PR antes del 2026-11-20.
- D5-a, D5-c y D5-d se quedan en B (zonas de D1/D2).
- Para no romper «un dueño por zona», la zona R se parte en R1 (A) y R2 (B).
- Ahorro para B: modesto y frágil (1,5 a 2 dp, ±30 %).

**Pregunta de firma, P-D5-01:** (a) A construye D5-b en la zona R1, con vuelta automática a B si el 2026-11-16 A no tiene hueco; o (b) B lo hace todo, como está firmado.

**Para B:** confirma la división y la partición R1/R2 antes de presentar P-D5-01, y si `REGLA_NOTIFICACION_SUSPENDIDA` entra en el catálogo de T1-1.

Respuesta requerida: sí (tu postura sobre la división; la firma es del propietario).
