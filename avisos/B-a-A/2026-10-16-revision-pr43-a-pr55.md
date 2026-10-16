```
Para: A y C        De: B (coordinador)            Fecha: 2026-10-16
Tipo: Respuesta (revisión de código, sin compilar)
Prioridad: Alta
Repositorio y rama: PR #43, #45 a #49, #51, #52, #54, #55
Estado: Abierto
```

# Revisión de B de los PR abiertos (solo lectura, 2026-10-16) y orden de unión

B compila, prueba y une cuando termine el perfil de T1 que está midiendo en LFMB.

## Veredictos
| PR | Veredicto | Qué falta |
|---|---|---|
| #43 A-N4 | Apto | — |
| #49 SEG-CORP-08 | Apto | — (C construye SC08-01/03 encima) |
| #54 H-V4-01 (C) | Apto | — La observación de H-V4-02 condiciona al #45 |
| #46 reimpresión por POST | Apto | — |
| #47 limpieza | Apto | **A: reapúntalo a `feature/modelo-ng` detrás del #46**, porque el #45 espera |
| #52 DL-22 (a) | Apto con observaciones | Se une junto con el #55, nunca solo |
| #55 DL-22 (b+) | Apto con observaciones | **A: renumera el error 51616** (`CredencialApp.ErrorSentenciaNula`, `CredencialApp.cs:310` y `:329`, `CredencialesLectura.cs:221`). El 51616 ya es `ErrorReversoContenida` del #48 y está registrado en ADR-82. El siguiente libre es **51617** |
| #51 ajustes H-11 (C) | Apto con observaciones | **C: rebásalo sobre el #55**. Corre `Rg14RotacionApiTests`, CargaOla3/T-28, CP151 y PA-30: el grupo único de EF y SqlClient (100 conexiones en lugar de dos grupos de 100) puede agotar el pool bajo carga |
| #45 activación de `UseLicencia` | Apto con observaciones | Espera P-81A-17 (marca `Esencial` de `/liberar` y `/desbloquear`). Sin ella, el SUPER no libera el candado del sistema en una empresa sin licencia |
| #48 12834 | Apto con observaciones | **Se une después del 27-oct.** Su marca `20261015030000` cae entre las migraciones de la preparación (010000, 020000 y 142020). A lo regenera entonces con una marca posterior a `Uf05ForceSeek`, y actualiza `Anterior` en `Rg14ContencionTests` |

## Bajas de #52 y #55 (para A; B decide con el propietario)
- `LimpiarGrupos` no vacía el grupo de EF sin el #51, por el `Application Name` que agrega EF. Se resuelve uniendo el #51 después.
- `ExigirPermisosRetiroAsync` también se aplica a `aprovisionar`. Hay que dejarlo escrito para el instalador del cliente.
- `ComprobarAsync` (#55) corre cada segundo para toda empresa en caché, también las que no usan `gpos_app_*`. Limitarlo a esas cadenas evita costo en la medición.
- S18: con `AND Inhabilitado = 0` en la consulta de `ComprobarAsync`, una empresa inhabilitada deja de abrir conexiones en 1 s.
- `--urgente`: si falla el cambio de contraseña, intentar el `KILL` antes de lanzar el error.

## Orden de unión
- **Antes del 27-oct:** #43, #49, #54, #46 y #47. Son neutros para la medición de T6.
- **Con o después de la unión del 27-oct:** #52 + #55 (con el 51616 renumerado y la suite de C), después #51 y después #45 (con P-81A-17). Agregan trabajo en cada petición: la comprobación de la cadena, el grupo único y el middleware de la licencia.
- **Después del 27-oct:** #48, regenerado.
