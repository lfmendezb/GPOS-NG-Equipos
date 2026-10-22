```
Para: B        De: A        Fecha: 2026-10-22
Tipo: Informe (revisión de seguridad del #152, T4-01) y decisiones de A sobre S152-02, S152-03/P152-08, D-25 y D-26
Prioridad: Alta (condiciones para unir el #152 y para T4-02)
Repositorio y rama: GPOS-NG `b/ola5-t4-01-render` @ cf6ccf98 (#152); informe en `traspasos/A/revision-seguridad-pr152-t4-01-2026-10-22.md`
Estado: Abierto
```

# Revisión de seguridad del #152: aprobado con observaciones

Recomendación técnica; la orden de unión es del propietario. Solo lectura (`gh`, `git show`, `git grep` sobre `origin`; nada compilado ni ejecutado). **Sin Críticos ni Altos.**

## Tus tres correcciones: cierran, sin regresiones ni evasiones
- **S152-01/P152-01:** dos barreras (filtro 404 antes de autenticar y comprobación del canal en `RenderAsync`, antes del plazo y de leer el cuerpo); la segunda cubre Release, donde la prueba del `Program` real no corre.
- **P152-04:** política por omisión con sesión y 401 probado en las 4 rutas; la revocación se ve en ≤ 15 s por la caché (lo firmado en la cl. 6).
- **P152-05:** el cuerpo se lee tras autenticar y el tope de 16 MB se controla por `ContentLength` y por lo acumulado.

## Hallazgos de la revisión general
- **Medios:** R152-04 (= S152-02; además del bucle sin fin hay recursión sin fin, que desborda la pila y termina el proceso, y reservas de memoria sin medir contra `HeapHardLimit`); R152-05 (= S152-03: el logo de la empresa se emite en `src` sin comprobar que sea `data:`, `GeneradorRazor.cs:101`, y el cortafuegos de Windows no filtra loopback); **R152-06 (nuevo):** Chromium se lanza sin `Pipe = true` (`ConvertidorPdf.cs:106-110`) y por omisión usa el puerto de depuración TCP sin autenticación en loopback [I: falta confirmarlo con `netstat`]; otro usuario local podría tomar el navegador, que corre como `NT SERVICE\GPOS.Reportes`; el precalentamiento está activo por omisión (`appsettings.json:41`); R152-07 (= DM-11: perfil en TEMP con nombre de 32 bits, nunca se borra); R152-08 (lista negra del validador de plantillas evadible).
- **Bajos:** R152-09 (caché de plantillas sin tope), R152-10, R152-11, R152-12, R152-13 (= DM-04), R152-14 (el render no lee `rptsis`: escribirlo como precisión que caduca en T4-11).

## Decisiones de A sobre lo que pediste
- **S152-02:** lo propuesto **basta para T4-02 con cuatro ajustes** (C-02-1 a C-02-5, ~2,25 dp ±40 %): (1) dos grupos, con al menos 2 cupos propios para el estándar; (2) cuarentena por la misma huella que la columna `Huella` de la cl. 7 (T4-10), guardada en disco y marcada al empezar el render; un formato en cuarentena se imprime con el formato estándar y deja evento, para que la caja siga imprimiendo; (3) el 503 en `/api/salud` no reinicia nada; al llegar al tope de hilos huérfanos el servicio se reinicia de forma controlada; (4) el instalador configura la recuperación del servicio (lo único que cubre el desbordamiento de pila). `HeapHardLimit` ya está (768 MiB): falta medirlo. **Razor en proceso hijo: decidir a favor el 20-nov y construir tras el corte**; mientras, Razor sigue solo para el SUPER.
- **S152-03/P152-08:** **T4-03 como condición de T4-02, no la aceptación de riesgo.** Núcleo (~1 a 1,25 dp): solo `data:` y `about:blank`; `Pipe = true`; perfil según DM-11; logo e imágenes revalidados al renderizar; JS de la página apagado si una prueba confirma que la medición del rollo sigue funcionando [I]. La aceptación de riesgo firmada por el propietario queda solo de respaldo, con caducidad. **Ojo con el plan:** T4-03 estaba previsto para después del 20-nov y A la dejó fuera de lo suyo; el núcleo debe estar antes de unir T4-02.
- **D-25:** defecto de integridad del documento, no de confidencialidad: `size: letter` (`PlantillasRazor.cs:37`) con `PreferCSSPageSize` pierde ~5,9 mm del borde derecho en A4 (donde van los montos) y en Media carta los totales pasan a otra hoja. No capturar esos dorados hasta corregirlo (cambio aparte, ~0,25 dp). No bloquea el #152.
- **D-26:** a favor de la comparación estructural con PdfPig como puerta, más: presencia de NCF, totales, «COPIA n» y «Reimpreso el»; y que el PDF no tenga contenido activo (`/JavaScript`, `/Launch`, `/EmbeddedFile`). La comparación por imagen, solo informativa.
- **DM-11 y DM-04** aplican al #152 (R152-07 y R152-13).

## Condiciones
- **Para unir el #152:** U-1 suite de reportes en verde (B informa 469/0; A no lo verificó); **U-2 `Pipe = true` o `Precalentar: false` hasta T4-03, como mínimo antes del primer despliegue (DEMO).**
- **Para T4-02:** C-02-1 a C-02-5; núcleo N-1 a N-5 de T4-03; R152-09, R152-12 y R152-13; R152-14 escrito; y la fuga de pestaña al cortar en `NewPageAsync`.

Decisiones candidatas a ADR (arquitecto-maestro de B): precisión de la cl. 6 de ADR-109 para el render puro (caduca en T4-11); proceso hijo para Razor (20-nov); imprimir con el formato estándar si el personalizado está en cuarentena. Supuestos [I]: puerto de depuración por omisión; cortafuegos sin filtro de loopback; desbordamiento de pila termina el proceso; no se corrió análisis de paquetes vulnerables; el informe de seguridad de B se tomó del aviso y del cuerpo del PR (no está como archivo en el área común).

Respuesta requerida: B aplica U-2 y lleva al propietario la orden de unión con las condiciones para T4-02; acuse antes del 2026-10-29.
