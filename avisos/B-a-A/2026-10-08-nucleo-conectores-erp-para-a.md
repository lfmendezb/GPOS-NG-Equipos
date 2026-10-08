```
Para: A            De: B            Fecha: 2026-10-08
Tipo: Aviso
Prioridad: Normal
Repositorio y rama: GPOS-NG b/conector-admcloud-diseno (aadd927)
Estado: Abierto
```

# Núcleo común de conectores ERP: lo que toca a A en T-29 y una prueba de 73.7.6 que no existe

El arquitecto-software de B terminó el diseño del núcleo común de conectores ERP (X-2 de ADR-73): `docs/arquitectura/2026-10-08-nucleo-conectores-erp.md`. Es una propuesta, pendiente de firma.

**El modelo:**
- **El núcleo empuja.** La cláusula 73.7.2 prohíbe que un complemento lea tablas.
- **Cursor:** se lee `Version` (rowversion) con el límite `MIN_ACTIVE_ROWVERSION()`.
- **Canal `R`:** nuevo en `sync.Salida`, lleva solo identificadores.
- **Sobre:** se congela al primer envío en `integ.Envio`, con huella.
- **Servicio:** uno de Windows por proveedor, como IQ.
- **Paquete:** un solo `GPOS.Conectores.Contratos`, con tres espacios: `Comun`, `Ecf` y `Erp`.
- **Las vistas de ADR-109 no se usan:** su cláusula 14 las reserva a los clientes del núcleo.

**Para A:**
1. **`NucleoSinProveedoresTests` no existe**, ni en `master` ni en `feature/modelo-ng`, aunque la hoja de ADR-73 la ubicaba en la ola 4. Hoy nada vigila la cláusula 73.7.6 (el núcleo no conoce proveedores). Proponemos que entre en el cierre de la ola 4 o en la ola 5. Es pequeña: de 0 a 0,05 sp.
2. **T-29:** B propone que la interfaz `IClienteConectores`, el cliente del núcleo hacia los conectores, separe el espacio `Comun` del de `Ecf`, para que los conectores ERP la reutilicen. **El riesgo R-01:** X-2 depende de T-29; si T-29 se atrasa, el conector de AdmCloud también.
3. **Verificado en `f21b788`:**
   - el `CHECK` del canal de `sync.Salida` admite solo `S`, `E` y `C` (`SyncConfiguracion.cs:18`). El canal `R` se agregará después del corte, sin tocarlo ahora;
   - `fiscal.Impuesto`, `cat.Moneda` y `cat.TasaCambio` no tienen `rowversion`. El diseño lo resuelve con la huella del catálogo, **sin tocar su DDL**.
4. **Ola 5, de B, sin mover el calendario:**
   - los nombres de columnas comunes entre la exportación X-1 y el sobre ERP;
   - `rpt.TotalesControl` por día de registro;
   - la reserva de nombres: esquema `integ`, canal `R`, privilegios y módulo `CONECTOR_ERP`.

**Esfuerzo de X-2:** unas 2,35 sp (de 1,6 a 3,3), frente a las 2,0 firmadas. Se construye después del corte. El propietario todavía no lo ha firmado.
