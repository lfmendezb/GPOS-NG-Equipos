```
Para: A        De: B (coordinador)            Fecha: 2026-10-14
Tipo: Hallazgo
Prioridad: Alta
Repositorio y rama: GPOS-NG a/h11-p7-candado (PR #24), con #26 y #28 apilados
Estado: Abierto
```

# H-11: tras una restauración real con la API encendida, la empresa responde 500 de 5 a 60 s (PoolBlockingPeriod). Se corrige en #24 antes de unir

**Decisión del propietario (2026-10-14):** «Que A corrija primero el 500 tras la restauración (PoolBlockingPeriod) en #24 con su prueba de regresión y validación del arquitecto; después unes #24, #26, #21 y #28.»

## Síntoma (se reproduce en LFMB, en `.\SQLEXPRESS` y en `.`, también en tu punta `c33231009`)
- `CandadoRestauracionApiTests`, corrida como clase completa: `Sonda_C2_01_b_rango_ampliado_y_respaldo_anterior_al_desbloqueo` falla con `GET /api/admin/sitio/restauracion: 500`. Detrás cae en cascada `Restauracion_real_de_la_empresa…` (503 `BASE_RESTAURADA` al crear un artículo).
- Para reproducirlo basta el par `--filter "FullyQualifiedName~Sonda_C2_01_b|FullyQualifiedName~C2_04_una_copia"`. Sola, la Sonda pasa.

## Diagnóstico (desarrollador de B, con registro temporal en `ManejarErrorAsync`)
- **Excepción:** `SqlException 18456: Login failed` en `ConexionTransaccion.ActualAsync` (`ConexionTransaccion.cs:26`), llamada desde `RestauracionSitioService.ExternosAsync` (`:280`, `NodoLocal`, fuera del `try`) ← `EstadoAsync` (`:49`) ← `RestauracionEndpoints.cs:20`.
- **Causa raíz: el período de bloqueo del pool de Microsoft.Data.SqlClient** (`PoolBlockingPeriod=Auto`). Durante el segundo RESTORE, `TrabajoRespaldosPosteriores` abre la base de la empresa con la misma cadena y recibe dos 18456 («Infrastructure error» en el registro de SQL). El pool guarda ese error y **lo repite** a toda conexión nueva durante 5 s, hasta 60 s si se repite. El servidor no registra ningún login nuevo y `SqlConnection.ClearPool` no lo limpia. C2_04 solo cambia los tiempos.
- **Clasificación: defecto del producto.** Con la API arriba durante un restore real (R-6), un login fallido de cualquier origen (cajeros, trabajos) deja a la empresa respondiendo 500 en lugar del 503 controlado.
- **Confirmación:** con `PoolBlockingPeriod = NeverBlock` temporal en la cadena de pruebas, el par pasa 2/2 y la clase 4/4.

## Pedido
1. **Corregir en #24** con la validación de tu arquitecto de software. Propuesta mínima del diagnóstico, en `src/GPOS.Core/Sistema/EmpresasService.cs:32`:
   ```diff
   -        cs = e is null ? null : cifrador.Descifrar(e.ConexionCifrada);
   +        // Tras un RESTORE con la API arriba, el pool no debe repetir un error de login viejo (PoolBlockingPeriod)
   +        cs = e is null ? null : new SqlConnectionStringBuilder(cifrador.Descifrar(e.ConexionCifrada))
   +            { PoolBlockingPeriod = PoolBlockingPeriod.NeverBlock }.ConnectionString;
   ```
   - Revisar también `EmpresasService.cs:194` (otra lectura de la cadena) y `RespaldosPosteriores.cs:85`.
   - **Alternativa descartada:** traducir 18456/4060 a 503 en `ManejarErrorAsync`. Oculta el síntoma y el pool sigue bloqueado.
   - Que el arquitecto valide el efecto de `NeverBlock` en una caída real del servidor: más intentos de login, sin la espera del pool.
2. **Prueba de regresión:** forzar un login fallido durante el restore y comprobar que la R1 siguiente responde 200 (o el 503 controlado), nunca 500. Que la clase `CandadoRestauracionApiTests` completa pase.
3. **Incluir en #24 la corrección de prueba de B `455a7c4`** (`DesbloqueoRestauracionTests`): el alta que solapa el bloque X por debajo del piso acepta 51324 o 51404, porque sin `sp_settriggerorder` el orden de los dos disparadores de `fiscal.SecuenciaNcf` varía entre equipos. Basta con un cherry-pick, o la aplica B al unir.
4. **Rebasar #26 y #28 sobre el #24 corregido.** Si la corrección no trae migración, las marcas no cambian: H11 `20261014204007`, C-10 `20261014205000` (lo regenera B) y Rg14 `20261014210613`.
5. Avisar con un aviso Entrega, con las cifras de la suite oficial y de la clase.

## Estado de la integración de B (respaldado en GitHub)
- `b/integracion-pendiente-14oct` (`455a7c4`): `e59d8de` + #24 + #26 + #21 (C-10 rebasado por B, `b/c10-compra-variable-tabla`) + #28.
  - El guion acumulado queda regenerado hasta `20261014210613_Rg14PrivilegioMinimo`.
  - El `Designer` de Rg14 queda alineado con el snapshot (le faltaba el `INCLUDE` de C-10).
- **Verificado:**
  - Web 649/649; MAUI 561/561.
  - Suite oficial: 2552 correctas. Hubo 4 fallas: 2 de carga (pasan solas), la del orden de disparadores (corregida en `455a7c4`) y la de esta clase.
- **No se publica nada en `feature/modelo-ng`** hasta tu corrección. Después B une #24, #26, #21 y #28, en ese orden.
- Ya aceptado por B: el cambio del `Down` de RG-14 que repone el GRANT de H-11.
