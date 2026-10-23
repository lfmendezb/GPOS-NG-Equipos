Para: B        De: A        Fecha: 2026-10-22
Tipo: Entrega (revisión del #168 con la política AdminSinRestriccion y del #178 revisión 5)
Prioridad: Media
Repositorio y rama: GPOS-NG #168 `b/e1-adr93-alcance-sucursal` (`11207ad7`) y #178 `b/datos-t4-10` (`af9e4123`)

# #168: Aprobar con observaciones · #178 rev. 5: Aprobar

Informe: `traspasos/A/revision-168-excepciones-y-178-rev5-2026-10-22.md`. Lectura estática; no corrí las pruebas de B.

**#168 [V]:** la política cubre todo `/api/admin` (incluidos `diagnostico`, `motivos-anulacion` y `sucursales/{codigo}`); las 8 rutas de la lista de excepciones están acotadas en el servicio; sin oráculo de existencia; `/api/admin/reportes` de la API de reportes queda igual de cerrado por `PuedeDisenar`. Sin hallazgos Altos ni Medios.
- O168-01: EventId 5120 libre en mi reparto; confirmar `EventIdUnicosTests`.
- O168-02: el limitador de D81-10 deja solo el primer sondeo del minuto.
- O168-03: efecto aceptado del USER restringido con 403 en conciliación, motivos, cierre y listas de precios.
- O168-04: falta ocultar opciones denegadas en la Web y MAUI y la etiqueta en español del evento (tarea 7).
- O168-05: citar en la hoja la prueba que recorre los endpoints de `/api/admin` (o agregarla).

**#178 rev. 5:** S178-R4-01 a R4-07 incorporadas y coherentes con mi diseño del sello; revisé el resto de `EfectivoEndpoints` y ninguna otra ruta con `AperturaCaja` o `CierreX` devuelve movimientos de caja.
- O178-R5-01: `Notas` y `MotivoAnulacion` son texto libre dentro del DTO sin montos; sacarlos del DTO del X o anotarlo en R19.
- O178-R5-02: el evento informativo del recorte (S178-R4-05) no tiene EventId; propongo 5155.

**Mío:** `a/usuarios-razor-restriccion` rebasada sobre `11207ad7` (`48bce01e`), empujada, Web compila. Agrego la lectura de `auth_time` (R20) al diseño del sello.

Respuesta requerida: B decide O178-R5-01 y O178-R5-02 antes de construir T4-10. Nada se une sin orden del propietario.
