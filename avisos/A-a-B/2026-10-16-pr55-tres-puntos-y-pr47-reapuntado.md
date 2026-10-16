```
Para: B y C        De: A            Fecha: 2026-10-16
Tipo: Entrega
Prioridad: Alta
Repositorio y rama: GPOS-NG #55 (a/dl22-bmas @ 27ca3e2c) y #47 (base feature/modelo-ng)
Estado: Abierto
```

# #55: los tres puntos aprobados por el propietario, construidos y probados; #47 reapuntado

Responde a los agregados de `B-a-A/2026-10-16-revision-pr43-a-pr55` (decisiones del propietario y orden de unión).

## #47
- Base cambiada de `a/reimpresion-post` a **`feature/modelo-ng`**.
- Hasta que se una el #46, el PR muestra 2 commits: el del #46 y el suyo. Unir **#46 → #47**.

## #55 @ `27ca3e2c`

| Punto | Qué hace | Prueba |
|---|---|---|
| **1. S18** | `ComprobarAsync` lee con `AND Inhabilitado = 0`. Sin fila, descarta la entrada (solo si nadie puso otra), vacía sus grupos y deja una línea Information sin la cadena. `ObtenerAsync` devuelve null | `DL22_S18_al_inhabilitar_la_empresa_deja_de_abrir_conexiones_en_1_s`: en ≤ 1,5 s la API ya no da la cadena y quedan 0 sesiones; al habilitarla, vuelve. **3 de 3** |
| **2. `--urgente`** | Si el `ALTER USER` de la anterior falla después del `DENY`, intenta igual el `KILL` (`CerrarSesionesAsync` con plazo 0). Después lanza el error, que dice si las sesiones se cerraron | Bloque nuevo en la prueba de rotación de `credencial-app`. Un disparador rechaza solo el `ALTER USER` de `gpos_app_b` con una sesión suya abierta. Resultado: el error lo dice, 0 sesiones de b, b sin CONNECT y a vigente |
| **3. `ComprobarAsync` limitado** | La comprobación de cada segundo solo corre si el `UserID` de la cadena empieza por `gpos_app_` (`Vigente.Rotable`, calculado una vez) | `DL22_bmas_con_seguridad_integrada_la_cache_no_consulta_GPOS_SYSDATA`: con otra cadena guardada, la empresa inhabilitada y GPOS_SYSDATA fuera de línea, sigue la vigente en el acto y sin aviso |

**Efecto del punto 3 que B debe conocer:** con seguridad integrada, S18 tampoco actúa. Una empresa inhabilitada sigue abriendo conexiones hasta reiniciar la API, como antes de DL-22 (b+). En producción (`gpos_app_*`) no cambia.

**Pruebas existentes adaptadas al punto 3:**
- `DL22_bmas_la_cache_toma_la_cadena_nueva…` usa ahora un inicio de sesión temporal `gpos_app_t_*` y pasa a `[FactModoMixto]`.
- `…con_GPOS_SYSDATA_caida…` usa una cadena `gpos_app_t_*` que nunca abre.
- `LoginsPruebaRg14` crea y barre también los `gpos_app_t_*`. No chocan con `gpos_app_a|b`, que son usuarios contenidos.

## PA-30: un 503 controlado nuevo
- En la primera corrida dirigida salió **1 de 6672: un 503 `ESTADO_CANDADO_NO_DISPONIBLE` sin `Retry-After`**. Lo da `ModoCandadoRestauracion.cs:75`, cuando la lectura del candado de la empresa falla justo antes de una escritura.
- Es el fallo seguro de H-11, no un 500. La prueba ya lo admite junto con el 503 que vio C (con `Retry-After`), dentro del mismo tope del 1 %.
- **Después:** PA-30, 3 corridas: 7462, 7770 y 7704 peticiones, **0 fallidas y 0 con 503**. Ventanas: credencial de 3,50 a 3,67 s; sesión de 15,02 a 15,13 s.
- **Observación para B (no cambié producción):** ese 503 del candado no lleva `Retry-After`, a diferencia del de la base no disponible. Si se quiere uniforme, es un cambio de una línea en `ModoCandadoRestauracion`.

## Verificación
Instancia `.` (SQL 2019, modo mixto). `Rg14Lote2*`, `Rg14Rotacion*` y `EsquemaPendienteAcceso*`: 26 de 29 en la primera corrida. Las 3 fallas:
- la comparación de la prueba S18 nueva (corregida);
- el 503 de PA-30 (descrito arriba);
- `EsquemaPendienteAccesoTests.Una_empresa_cuya_base_no_existe…`, que **también falla sola sobre `81b00f2b`, sin estos cambios**. Es la previa anotada el 16-oct.

**Para C:** la suite oficial del #55 se vuelve a correr sobre `27ca3e2c` cuando toque unirlo, después del 27-oct.

## Cola de A
- Esperan a B: SC8R-03/04 (aviso `2026-10-16-sc8r07-pa30-y-propuesta-sc8r03-04`).
- Después del 27-oct: regenerar la marca del #48.
- Sin otra tarea desbloqueada.
