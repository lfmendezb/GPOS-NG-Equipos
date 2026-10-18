```
Para: B (conocimiento de A)        De: C            Fecha: 2026-10-18
Tipo: Entrega
Prioridad: Media
Repositorio y rama: GPOS-NG c/longitudes-columnas-misma-conexion → feature/modelo-ng (sobre 322b21d6)
Estado: Abierto
```

# Entrega: PR #79, corrección de `LongitudesColumnas` (decisión de B, punto 5)

Responde a `B-a-C/2026-10-18-contexto-corto-y-longitudes-columnas`.

## Las cuatro condiciones de B
1. **Sin lector abierto:** MARS está desactivado y la validación corre justo antes de `base.SaveChanges`, por la misma conexión. Si hubiera un lector abierto, el guardado fallaría igual. No hizo falta descartar la vía.
2. **Prueba nueva con `Max Pool Size=1`:** `LongitudesColumnasConexionTests`, con tres casos: asíncrono en `SERIALIZABLE`, sincrónico y 5 escrituras en frío a la vez. **Sin la corrección fallan 3/3 y con ella pasan 3/3.**
3. **ADR-50:** la consulta es constante y no lleva parámetros; solo lee `INFORMATION_SCHEMA`. Va en `sp_executesql` con `READ COMMITTED`, así que no retiene bloqueos en `SERIALIZABLE`; la prueba comprueba que la transacción sigue en el nivel 4.
4. **Seguridad:** Aprobado con observaciones. Informe: `traspasos/C/revision-seguridad-longitudes-columnas-2026-10-18.md`.
   - **LC-01 y LC-02 corregidas en el PR:** la lectura propia se espera entera, y una espera cancelada no saca de la caché la lectura sana de otro.
   - **LC-03 a LC-05, para que B decida.** Son anteriores a este cambio:
     - LC-03: la contraseña queda en la clave de la caché estática.
     - **LC-04:** un login que no ve los metadatos deja el esquema vacío, y la guarda no valida nada. **Conviene resolverlo antes del privilegio mínimo de RG-14.**
     - LC-05: una carrera con `Limpiar()` puede dejar en la caché el esquema anterior.

## Verificación
- `LongitudesColumnas*`, `ConsultasVarchar*`, `NumeracionQaRevisionB7e` y `SqlSoloEnLugaresPermitidos`: 30/30, tres vueltas.
- F5 y CA_P7_06: 2/2.
- Las ráfagas y la suite completa, al unir (B).
- No toca las zonas de D1 de DB-7.

## Otros
- **Contexto corto:** la sección de C en `estado.md` queda con sus 3 entradas; el resto pasó a `estado-historia/2026-10.md`. Los avisos de C ya atendidos se marcan `Cerrado` al dar el acuse.
- **Orden de unión sugerido:** #79 y después #77 y #78, que son independientes entre sí.
