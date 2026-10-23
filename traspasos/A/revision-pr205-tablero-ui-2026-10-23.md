# Revisión del #205 (T4-07, interfaz del tablero), ya unido

PR: `b/ola5-t4-07-ui` (`0c337831`, merge `e49fce66`), 7 archivos, +261/−12. Revisión de A, solo lectura del diff; no se compiló ni se corrió nada. Dictamen: **Aprobado; 4 observaciones Bajas y una de texto (UX).** Sin hallazgos de seguridad. Cierra T4-07-01 en la interfaz.

## Lo comprobado
- 503 `REPORTES_NO_DISPONIBLE` y 403 `SUCURSAL_NO_PERMITIDA`: `CargarKpisAsync` los pasa por `manejarError` de `EjecutarAsync`, que devuelve `true` solo para esos dos códigos (`VistaTablero.TextoDeError`); los demás errores siguen el camino general. Sin aviso emergente, y el refresco automático de 5 minutos ya no repite el mensaje.
- El tablero ya no se oculta cuando hay error (`_errorKpis is null` en la condición de ocultar); con error no se piden los gráficos y los avisos de la principal siguen cargando.
- **No se muestra texto del servidor:** los textos son constantes; las pruebas comprueban que «Detalle técnico.» y «La sucursal no es válida.» no llegan al marcado. `AlcanceSucursal` se pinta como texto (Razor lo codifica).
- Web y MAUI iguales (`Tablero.razor` y `VistaTablero.cs`); las pruebas de MAUI son de la vista, no del componente.

## Observaciones
| Id | Sev. | Hallazgo | Remedio |
|---|---|---|---|
| R205-01 | Baja | `CambiarPeriodoAsync` solo recarga las tarjetas. Tras un error, `CargarAsync` dejó `_graficos = []`; si el servidor responde al cambiar de período, las tarjetas vuelven pero los gráficos no hasta pulsar Actualizar o el siguiente ciclo de 5 minutos. | Que `CambiarPeriodoAsync` también llame a `CargarGraficosAsync` cuando `_errorKpis` pasa de no nulo a nulo. |
| R205-02 | Baja | Falta la prueba del componente para un error **distinto** de los dos (debe seguir el camino general); `Los_codigos_desconocidos…` prueba solo la función. | Una prueba bUnit con 500 o `ERROR_X`: aparece el aviso general y no el cuadro fijo. |
| R205-03 | Baja | Falta la prueba de que el refresco automático con el error vigente no repite el aviso emergente (el motivo de T4-07-01). | Avanzar el temporizador o llamar al camino automático y comprobar `Snackbar` vacío. |
| R205-04 | Baja | Las pruebas de MAUI cubren `VistaTablero`, no el componente; la copia MAUI de `Tablero.razor` no se compiló en este análisis. | Mantener la prueba de paridad de fuentes (Web = MAUI) del resto de las páginas. |
| R205-05 | UX | Texto del 503: «El tablero no está disponible: el servicio de reportes no responde.» dice «no responde», pero en el DEMO de procesos el servicio **no existe**. El mismo código cubre «no instalado», «no configurado» y «caído». | Propongo «Los reportes no están disponibles en esta instalación o en este momento.» (lo fija UX; lo acepta el propietario). |

## Pendiente de A
La línea de la guía del DEMO (el DEMO de procesos no lleva la API de reportes y su tablero muestra ese aviso): va con PR-D2.
