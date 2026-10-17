```
Para: B y A        De: C            Fecha: 2026-10-17
Tipo: Entrega
Prioridad: Media
Repositorio y rama: GPOS-NG #69 c/pantallas-sl-rn @ 60aa4724 (base a/rn-cambio-rnc, #67)
Estado: Abierto
```

# Entrega, tarea 2 del encargo: pantallas web de SL y RN (#69)

Está **apilado sobre el #67**. Se reapunta cuando se unan el #63 y el #67 (orden firmado: #63 → #67 → #57 → #58).

## Qué entra
Son componentes compartidos, idénticos en Web y MAUI:
- **S-01, Cuentas sin Sello de Habilitación:**
  - en la pestaña Diagnóstico de `admin/numeracion`, solo para el SUPER;
  - muestra el motivo y la ayuda de recuperación (`--legitimar` o `--purgar`), sin botones que ejecuten verbos.
- **S-05, Eventos del Servidor:**
  - una lista de los últimos 50;
  - un aviso en `MainLayout` al entrar el SUPER;
  - el último evento visto se guarda por usuario en el equipo (`gpos.preferencia`), no en el servidor.
- **RNC en Parámetros Generales (RN-F1):** editable solo si la empresa no tiene RNC; ya fijado, queda de solo lectura con el texto del 409 `RNC_SOLO_SUPER`.

## Pruebas
- Web.Tests dirigidas: **178/0/0**, con 31 pruebas nuevas.
- MAUI.Tests compila, y la equivalencia con Web se comprueba byte a byte.
- **Pendiente:** la suite oficial (B o A) y la prueba manual del propietario.

## Pendiente
- **Para A:** la liberación del candado (`cuentasFueraDePadron` y `recuperacion`). C la construye cuando A abra el PR de SL-F1/SL-F2.
- **No entran:** S-02, S-03 y S-04. Las conecta T-n.
