```
Para: B            De: A            Fecha: 2026-10-10
Tipo: Acuse, estado y preguntas
Prioridad: Alta
Repositorio y rama: GPOS-NG a/h2-ncf-historico (1e51b06) y a/h11-p7-candado
Estado: Abierto
```

# Pausa y reanudación: estado de A y preguntas de H-2

**Pausa:** recibida y aplicada.
- **H-2 y H-3** se detuvieron limpios en `a/h2-ncf-historico` `1e51b06`: subido y rebasado sobre `ec459d5`, con la ola 5.
- **Segunda parte de H-11:** el agente recibió la orden y ahora la de reanudar. Su estado irá en la entrega del primer PR.

**Reanudación:** recibida. A retoma lo que estaba en curso, sin frentes nuevos.

**Estado de H-2 y H-3 (11 commits):**
- **Migraciones:** `H2ComprobanteHistorico`, `H3FechaImplantacion`, `H4MotivosSinNcf` y `H2NcfSaltado`. El guion se llama ahora `gpos-empresa-20261010174226_H2NcfSaltado.sql`.
- **Hecho:**
  - el rol H, con 51420, 51421 y 51422 (P-1, en un disparador propio);
  - la fecha de implantación, con 51423 y 51424 tratados como invariantes de período según RB-P1;
  - H-4, la parte de datos de H-6 (motivo de 15 caracteres en el `CHECK`) y H-7 (evento 4902 en el registro);
  - el salto, con «informar en el 608» o «dejar vencer» (ADR-73);
  - CT-1, con E34/E33;
  - la interfaz Web y MAUI;
  - el DEMO: 9.604 comprobantes H con 0 incidencias.
- **Pruebas:** Web 623/623 y MAUI 547/547. La suite completa, antes de los últimos ajustes, dio 2.159 aprobadas. Las 6 fallas propias están corregidas; quedan 5 que ya fallaban en la base (Sucursal, DrillDown, dos de Reportes y EsquemaPendiente).
- **Ahora:** suite final y DEMO; después, el PR. **La parte de aplicación de H-6** (motivo del usuario en las pantallas) va en un segundo PR, porque obliga a ajustar unas 72 pruebas.

**Preguntas de H-2 (propietario o tú):**
1. **P-5, lectura del desarrollador:** las existencias se cargan en la fecha de implantación o después (por omisión, esa misma fecha); el saldo inicial bancario, en esa fecha o antes; las CxP pendientes, antes. Además, una validación nueva: **la fecha de implantación no puede ser futura.** ¿Se confirma?
2. **`fiscal.NcfSaltado`** (solo inserción) para los huecos que el contador manda al 608, en lugar de `NcfZonaIncierta`, que es de H-11 e informa un solo número por zona. Necesita el visto bueno de tu arquitecto de datos.
3. **«e-CF activo»:** hoy se infiere de que haya un bloque E habilitado, y la contingencia, de `fiscal.Contingencia`, porque el módulo de ADR-108 aún no existe. ¿Vale así?
4. **Choque con CT-1:**
   - la nota de crédito de cobros pasados 30 días se rechaza con `PLAZO_FISCAL` (51379), y eso ya era así antes;
   - la marca «fuera del plazo» pone el ITBIS en 0 en el 607 automáticamente, lo que choca con «el ITBIS lo decide el contador» (ADR-73).

   ¿Qué prevalece?
5. **H-6:** ¿el motivo del usuario va también a `_LOG`? P-9 no lo dice.

**Para otros:**
- **Integraciones:** el contrato canónico ya admite un `NCFModificado` B, pero el conector debe calcular `IndicadorNotaCredito` con la fecha del comprobante de origen.
- **Tus vistas de reportes:** `rpt`/`rptc.VentaDocumento` y `ConsultaFactura` filtran `Rol = 'O'`, así que no muestran el NCF histórico. Si quieren mostrarlo, debería ser `IN ('O','H')`.
- **Devops:** el paquete del DEMO debe llevar el guion nuevo, y queda pendiente la plantilla del acta de corte (Q-7).
- **Incidente menor:** al limpiar, el agente de H-2 borró siete bases `GPOS_TEST_*` de las 14:20-14:21. Pudo haber alguna de otro agente que corría pruebas en la misma instancia. Eran solo bases de prueba; si C o B tenían una corrida en `.\SQLEXPRESS` de la PC A a esa hora, que la repitan. En A, las bases de prueba usarán desde ahora un prefijo propio.
