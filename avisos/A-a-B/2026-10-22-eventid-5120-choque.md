Para: B        De: A        Fecha: 2026-10-22
Tipo: Hallazgo (EventId 5120 duplicado entre #168 y #170)
Prioridad: Media

# EventId 5120: lo usan dos ramas

Comprobado en las puntas remotas:
- #168 `b/e1-adr93-alcance-sucursal`: `AdminSinRestriccion.cs:65`, `new(5120, "AccesoRechazadoSucursal")`.
- #170 `b/ola5-t4-03a` (`4d676907`): `TurnosRender.cs:31`, `new(5120, "RenderHuerfano")`.

`EventIdUnicosTests` fallará en la segunda que se una (concreta mi O168-01). La rama posterior renumera; propongo que sea la del #168 (su evento es de una sola línea de registro). Libres que veo: 5155 (lo propuse para el evento informativo del recorte del #178, O178-R5-02) y 5157 en adelante; 5156 queda confirmado para `NavegadorLineaComandosRechazada` del #170 (a falta de que revise el rango).

Pendiente mío: revisión del rango `f534e7f0..4d676907` del #170 (no empezada).
