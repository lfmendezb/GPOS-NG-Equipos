Para: B        De: A        Fecha: 2026-10-22
Tipo: Entrega (dos revisiones de seguridad, solo lectura)
Prioridad: Media (condiciones para unir T1-1 y T1-4 de D1)
Repositorio y rama: GPOS-NG #167 `b/dat-d1-rev3` y #162 `b/adr161-datos`; informes en `traspasos/A/`
Estado: Abierto

# Revisiones de seguridad: DAT-D1 rev. 3 (#167) y datos del ADR-161 (#162)

Las dos son **Aprobado con observaciones**, sin Críticos ni Altos. Recomendación técnica; la decisión es de B y del propietario. Solo lectura sobre los documentos; no se compiló ni se ejecutó SQL.

## DAT-D1 rev. 3 (#167): 3 Medios y 6 Bajos
Informe: `traspasos/A/revision-seguridad-dat-d1-rev3-2026-10-22.md`.
- **Cierre de D1-01 a D1-06:** cerradas D1-01, D1-04, D1-05 y D1-06; **parciales D1-02 y D1-03**. D1-07 y D1-12 siguen abiertas y aplazadas en 11 b.4.
- **R3-01 (Media, antes de unir T1-1):** H-13 está firmada, pero el texto del bloque 5 b (DAT:981-985) conserva el `@ckCaso` anterior; el firmado solo aparece en 11 b.1, que aún dice «(propuesta)», y la prueba de la `CHECK` no incluye `------` ni `--MOTIVO`. Con eso la base aceptaría `--MOTIVO` como número de caso.
- **R3-02 (Media, antes de unir T1-4):** la guarda del modo DEMO reutiliza `Vigente?.Anillo is Produccion or Beta`; sin licencia vigente deja pasar, y una instalación de Producción con la licencia vencida podría convertirse en DEMO con ADMIN en todas las empresas. Remedio: lista blanca de Desarrollo y Demostración con la firma verificada. **Si T1-4 se une sin R3-02, ese PR pasa a Rechazado.**
- **R3-03 (Media, antes de unir T1-4):** la instantánea protegida de `ConversionAccesos` no queda atada a una conversión concreta; una copia de la base en la misma instancia podría reemplazarla y D3 sellaría ese sobreacceso.
- **Bajos R3-04 a R3-09:** la marca vive en `Configuracion` (la API escribe); Q23 no verifica la instantánea; los rechazos del verbo no dejan evento; la instantánea se conserva sin plazo (Ley 172-13); numeración y marcas desactualizadas; el ingreso del SUPER debe fallar cerrado si falla su registro en la bitácora.
- **Datos desactualizados (R3-08):** los documentos dan el EventId **4742** como libre, pero lo usa `a/dv07-formato-licencia` (#103), y 4743-4744 ya están en `feature/modelo-ng`. La última marca de EF es `20261021001638_Ola5VistasTramo4`.
- **Sin colisiones de errores SQL:** ningún uso de 51619 a 51644 en ninguna rama. CS-P2 no tiene inyección (el SQL dinámico solo concatena constantes). Repetir un número de caso es lo aceptado por ADR-92 (CS-09).

## Datos del ADR-161 (#162): 4 Medios y 4 Bajos
Informe: `traspasos/A/revision-seguridad-adr161-datos-2026-10-22.md`. Cinco preguntas para especialistas (P-1 a P-5) en el informe.
- **R161-01:** los tipos no numéricos (pasaporte, carnet) aceptan cualquier carácter (ni el servicio ni `CK_Cliente_Identificacion` lo impiden): solo `[A-Z0-9]` y ampliar el CHECK de la rama `P`.
- **R161-02:** el 409 de Q-TI-5 entrega al SUPER las identificaciones íntegras de terceros: devolver cantidad, `Codigo` e identificación enmascarada.
- **R161-03:** no se valida el dígito verificador del RNC y la cédula, aunque el validador existe (`Empresa.cs:175`).
- **R161-04:** la clasificación por omisión deja a la persona física con RNC como `EMPRESA` (menos protección, y sin derecho a la supresión de TT) mientras Q-TI-8 y Q-TI-9 no se firmen.
- **Bajos R161-05 a 08:** inmutabilidad de `Codigo` solo en el servicio; historial temporal con Id inexistente al borrar un tipo; siembra a medias sin error; `Down` sin guarda.
- **Código 51618:** ya lo usa `ComandosCambioRnc.ErrorOtroCambio` (ADR-82 y ADR-83, PR #67 `e0a99019`, antes 51616) y está dentro del rango 51618-51644 que B reservó para D1. D1 y ADR-161 deben empezar en **51619**; confirmen la reserva.

Nada se une sin orden del propietario. Respuesta requerida: acuse; B decide cuáles condiciones entran antes de T1-1 y T1-4.
