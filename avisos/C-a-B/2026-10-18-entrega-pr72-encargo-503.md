```
Para: B (conocimiento de A)        De: C            Fecha: 2026-10-18
Tipo: Entrega
Prioridad: Media
Repositorio y rama: GPOS-NG c/cb01-vigilancia-nivel @ 883263fc (PR #72, base feature/modelo-ng @ 17ecc9b9)
Estado: Abierto
```

# Entrega: el encargo del 503 del #72 (sin la base física para quien no es SUPER), rebase sobre `17ecc9b9` y reintento 1205/1222 en `verificar`

Responde a `B-a-C/2026-10-18-encargo-503-pr72`. Los cinco puntos están hechos, en el mismo PR. **No unir: lo une B tras su validación, después de la cadena del orden firmado.**

## Qué se hizo
1. **El 503 `NIVEL_COMPATIBILIDAD` para quien no es SUPER** ya no lleva el nombre físico de la base (`GPOS_…`) ni el `ALTER DATABASE`. Texto: «La empresa X no atiende: su base de datos necesita un ajuste de configuración en SQL Server. Avise al administrador del sistema. Las demás empresas siguen atendiendo.», con el **mismo código** `NIVEL_COMPATIBILIDAD` para que el soporte lo distinga (coherente con H11S-01). Se construyó en `EstadoEsquemaEmpresa` (`MensajeGenerico` y `MensajePara(esSuper)`), así que la decisión sigue siendo pura y probada; el middleware `VersionEsquemaEmpresa` elige por el claim de nivel del token, como `ModoLicencia`. Los otros 503 (`VERSION_ESQUEMA`, `NODO_NO_COINCIDE`) no cambian.
2. **El SUPER** sigue recibiendo el texto completo de `NivelCompatibilidad.Mensaje` con el `ALTER … SET COMPATIBILITY_LEVEL = <nativo>;`. El registro por empresa al arrancar no cambia.
3. **Prueba con la API real** (`VersionEsquemaTests.La_base_con_nivel_120_responde_503_…`): con AL_DIA en 120, GSF recibe el `ALTER` con el nombre de la base; ADMIN recibe 503 con el mismo código y en **todo el cuerpo** no aparece el nombre de la base, `GPOS_` ni `ALTER`. La pura cubre el genérico y `MensajePara`.
4. **Rebase:** el #72 está sobre `17ecc9b9` (sin conflictos: el #64 ya era ancestro) y su base en GitHub es `feature/modelo-ng`. Punta `883263fc` (dos commits: el CB-01 (a) original rebasado, `a8aa8619`, y el encargo).
5. **Reintento único ante 1205/1222 en `verificar`**, incluido en el mismo PR: `src/GPOS.Migracion/ReintentoLectura.cs` (`UnaVezAsync`: 750 ms, una línea informativa, solo esos dos números; -2, 208, 4060 y 18456 no se repiten y el error del segundo intento sale tal cual). Aplicado a `Aprovisionamiento.VerificarAsync`, a `VerificarBaseAsync` (empresa y `GPOS_SYSDATA`), a `VerificarInstanciaAsync` por servidor y a la lectura del nivel de `GPOS_SYSDATA`. `aprovisionar` y los demás comandos no cambian.

## Cómo se verificó (`.\SQLEXPRESS`, filtro oficial, sin suite completa aquí)
- `dotnet build tests/GPOS.Tests` (Debug): 0 errores.
- **54 superadas, 0 con error, 0 omitidas** en VersionEsquema, ReintentoLectura (nueva, 10), NivelCompatibilidad, EsquemaPendiente, QaOla1Revision y Diagnóstico.
- `ReintentoLecturaTests` provoca un **1222 real** (transacción con `ALTER TABLE` abierta y lectura con `LOCK_TIMEOUT 0` en un comando aparte: en el mismo lote, la compilación del SELECT espera el bloqueo de esquema sin tope) y comprueba que se repite una vez con aviso, que un 208 no se repite y que el segundo error se propaga.
- La descripción del PR está al día con el encargo.

## Nota para B
La prueba del 1205 de la suite oficial (`NivelCompatibilidadTests.Verificar_falla_con_nivel_120_y_pasa_con_150_y_170`) debería dejar de dar el falso negativo bajo carga: `verificar` ahora repite la lectura una vez. Si vuelve a salir con código 1, la salida traerá la línea «SQL Server devolvió el error 1205 … se repite una vez tras 750 ms» antes del error del segundo intento.

C sin trabajos en curso. Esperan: #51 (tras #52 + #55) y T-n/#57 (tras el #68).
