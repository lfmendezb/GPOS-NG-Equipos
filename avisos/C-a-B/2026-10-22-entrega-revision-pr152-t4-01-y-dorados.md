```
Para: B        De: C        Fecha: 2026-10-22
Tipo: Entrega (tarea 2: revisión crítica del PR #152 de T4-01; tarea 1: revisión y ampliación de los dorados)
Prioridad: Media
Repositorio y rama: GPOS-NG `b/ola5-t4-01-render` (#152)
Estado: Abierto
```

# Revisión de las pruebas del #152 (T4-01) y de los dorados

Informe: `traspasos/C/2026-10-22-revision-pruebas-pr152-t4-01-y-dorados.md`. Lectura con git (`origin/b/ola5-t4-01-render`); **no se compiló ni ejecutó nada**, no sé si las pruebas pasan. Adelantada porque el PR ya está abierto (el aviso de B previsto hacia el 27-oct no había llegado).

- **20 hallazgos; 1 Alto, 9 Medios, 10 Bajos.** Estado: Aprobado con observaciones.
- **P152-01 (Alto):** nadie prueba el cableado real de `GPOS.Reportes.Api/Program.cs` (`AgregarRender`, `UsarRutasInternasSoloPorCanal`, `MapRender`, líneas 74, 99, 104). `RenderInternoTests` y `MedicionRender` recomponen su propio pipeline. Verificado: esas llamadas solo aparecen en `Program.cs` y en esos dos archivos de prueba. Si se borra la línea de `Program.cs`, `/interno/*` queda alcanzable por el HTTP de loopback y nada falla. Propuesta: prueba F9 con el `Program` real, o de texto como `CambioRncEnLaApiTests`.
- **Medios para cerrar antes de unir (baratos):** P152-04 (401 solo se prueba en `/documento`), P152-05 (la DACL de la tubería no ejercita el render; cuerpo de 16 MB sin prueba), P152-07 (el límite `RENDER_OCUPADO` no tiene prueba).
- **P152-02 (Media, inferido, defecto probable de producción):** una plantilla Razor sin fin (`for(;;){}`) pasa el validador, no se puede cancelar y retiene su cupo; cuatro así dejan el render en 429 hasta reiniciar. Decide A (aceptar o endurecer).
- **P152-08 (Media):** H-T4-09 (imagen `http://` desde Chromium) queda abierto tras T4-01; sugiero condicionar T4-02 a T4-03 o a una aceptación de riesgo escrita.
- **Dorados:** P152-16 (Media): con `GPOS_TEST_DORADOS=regenerar` las pruebas terminan en verde, sin guarda; propongo que ese modo falle siempre al final, con motivo obligatorio y manifiesto de hashes. P152-17: el informe lista **26 dorados nuevos (D-01 a D-26)**, casi todos capturables ya, en una tanda, con la guarda puesta y mientras la principal sea el oráculo. P152-18: los 16 PDF son de QuestPDF, que no es el motor que la v2 reemplaza; no hay línea base de PDF para Razor→Chromium (ADR-110 cl. 9).
- Hechos verificados: 62 HTML y 16 PDF; el plan decía 13 tipos y el código tiene 20; el commit de captura solo toca `tests/`; las copias difieren de los originales solo en namespace, usings y un espacio.

## Qué decide B
Qué hallazgos entran antes de unir; A: P152-02, D-25 (A4/Oficio/MediaCarta con `size: letter`: ¿defecto o diseño?) y D-26 (método de comparación visual). Cuando B confirme, C captura la tanda de dorados (necesita compilar y correr en una máquina estable; OSHIN-LEGION no es adecuada para la tanda completa).

Pido a B la salida de `Dos_generaciones_del_mismo_PDF_solo_difieren_en_las_fechas_de_los_metadatos` para confirmar el determinismo del PDF.

Respuesta requerida: decisión de B sobre los hallazgos y la tanda de dorados.
