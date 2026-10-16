```
Para: B        De: A                          Fecha: 2026-10-16
Tipo: Hallazgo
Prioridad: Media
Repositorio y rama: GPOS-NG feature/modelo-ng @ ce33b2a8 (defecto previo, no lo introduce SEG-CORP-08)
Estado: Abierto — sin dueño; espera tu decisión
```

# Hallazgo del núcleo: eliminar renglones del POS no queda autorizado en el servidor (SC08-01 y SC08-03)

Salen de la revisión de seguridad de SEG-CORP-08 (`traspasos/A/revision-seguridad-seg-corp-08-2026-10-16.md`). Como pediste, van aparte del PR corto.

## SC08-01 · Media · ya existía
- Al eliminar renglones del POS, `POST /api/pos/autorizar` solo responde verdadero o falso, y la pantalla decide (`PosEndpoints.cs:76-79`, `DialogoAutorizacion.razor:47`, `PuntoVenta.razor:495-503`).
- La autorización concedida no queda registrada en el documento. Con un cliente modificado, se pueden eliminar renglones sin pedirla.
- **Remediación propuesta:** que la venta lleve las eliminaciones, que el servidor las valide con `ValidarAsync` y que las guarde en `doc.Autorizacion` con un tipo nuevo, `ELIMINA_RENGLON`. Cierra P-11 de ADR-68, que necesitará una precisión. Costo: unas 0,3 a 0,5 sp.

## SC08-03 · Baja
- El servidor acepta «Punto de venta · Autorizar» para eliminar renglones (`PosEndpoints.cs:77`).
- La pantalla solo omite el diálogo con `eliminarrenglon` o `EliminarArticulos` (`PuntoVenta.razor:497`).
- Un perfil a medida que solo tenga «Autorizar» se queda sin forma de autorizar. No abre una brecha, pero confunde.
- **Remediación:** quitar esa acción de la condición del servidor (lo más simple) o tratarla como privilegio propio en la pantalla.

## Para la vertical Corporativa (SC08-02)
- El validador no tiene un modo «solo otra persona»: la forma B siempre vale (`AutorizacionesSupervisor.cs:95-101`).
- Hoy es correcto según lo firmado. El reverso y la identificación sin carné de la Corporativa necesitarán un parámetro `soloOtraPersona`, con su prueba (unas 0,05 sp).
- Queda anotado para el diseño de la entrega 3.

## Qué necesito de ti
- **SC08-01 y SC08-03:** si A los toma ahora (después de DL-22) o en otra etapa. SC08-01 lleva la precisión de ADR-68 para firma.
