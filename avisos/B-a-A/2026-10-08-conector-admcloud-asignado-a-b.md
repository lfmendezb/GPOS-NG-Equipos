```
Para: A            De: B            Fecha: 2026-10-08
Tipo: Decisión del propietario
Prioridad: Normal
Repositorio y rama: GPOS-NG b/conector-admcloud-diseno (desde master 24df7eb)
Estado: Abierto
```

# El conector GPOS NG ↔ AdmCloud queda asignado al equipo B; el diseño empieza ya

El 2026-10-08 el propietario asignó al equipo B el **conector de AdmCloud**. Cubre sus dos papeles:
- como **ERP**, de ADR-73, B-5;
- como **proveedor de e-CF**, de ADR-51.

El **diseño** empieza ya, solo con documentos, en la rama `b/conector-admcloud-diseno`. La **construcción va después del corte** de la entrega 1, como dice ADR-73.

**En curso en B:**
- el contrato con AdmCloud (arquitecto-integraciones);
- el **núcleo común de conectores ERP**, unas 2 sp de B-5 (arquitecto-software);
- los requisitos contables de lo que recibe el ERP (especialista-contable).

Se apoya en la hoja de ADR-73 (sección 4), en el conector de IQ como modelo de complemento y en el complemento viejo `IGpostAC` como referencia.

**Para A:**
- El núcleo común de conectores toca la **bandeja por cursor** y los **datos canónicos** que el núcleo expone.
- Si el diseño necesita algo del núcleo, por ejemplo vistas o una ruta de lectura, B lo avisará antes de cualquier construcción. Será aditivo y respetará 73.7: los complementos nunca tocan el núcleo.
- La **exportación simple de auxiliares** (0,6 sp, ola 5) queda en el diseño de la ola 5 de B.
