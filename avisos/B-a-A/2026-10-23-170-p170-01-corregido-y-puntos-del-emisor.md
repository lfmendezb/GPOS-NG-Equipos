Para: A        De: B        Fecha: 2026-10-23
Tipo: Aviso (#170: P170-01 corregido) y respuesta a tus puntos 2 y 3 del emisor
Prioridad: Media
Repositorio y rama: GPOS-NG #170 (`b/ola5-t4-03a`, punta `89fce5b5`)
Estado: Abierto

# #170: P170-01 corregido; respuesta sobre el emisor (`autor-super`, `.PermiteTokenProgramado`) y PR-V

**P170-01 (`89fce5b5`, sobre `403da3ca`).** Una apertura de `<link` o `<script` sin cerrar lanza `FormatoInvalidoException` (400 `FORMATO_INVALIDO`) en lugar de cortar la pasada. Corrí `La_capa_0*`: 74/74. Pruebas nuevas:
- La apertura sin cerrar dentro de un comentario, `<style>`, `<title>`, `<textarea>`, CDATA y un valor de atributo, con una sugerencia real después. Se evidencia con una comilla suelta, porque con un `>` posterior la apertura se lee como etiqueta y se sanea como antes.
- La apertura que llega al final del texto.
- La prueba de 400.000 aperturas ahora espera el rechazo.
No corrí la suite completa de `GPOS.Reportes.Tests`.

**Siguen abiertos del #170:**
- P170-02 (caso cuadrático con `<link rel=stylesheet` repetido hasta un `>` final) y el tope de ~262.144 `<` con comprobación justo después de Razor, antes de `MarcarCopia`.
- P170-03, P170-04 y P170-05.
- P170-06: las mutaciones y el plazo propio (`WaitAsync` de 10 s) de la prueba de rendimiento.
- P170-07 (marca de copia oculta con `<body>` en un comentario) va como ticket aparte para el arquitecto-maestro.

**Emisor T4-04:**
- Confirmo `TokenServicioDenegadoException` con `MotivosTokenServicio.AutorSuper` (`"autor-super"`), en línea con tu acuse del 22-oct y con la P-1 firmada (opción (a): sin token programado para el SUPER). B propaga el fallo a `UltimoResultado`.
- `.PermiteTokenProgramado(...)` en `EndpointsReportes.cs`: no existe aún en `feature/modelo-ng`. [PENDIENTE DE DEFINIR: la firma exacta y quién la escribe. Dime cómo la declara tu emisor y la pongo en el PR de B, o la incluyes tú en el PR del emisor. Respondo antes del 28-oct.]

**PR-V (lo que es mío):**
- Verbo `red` (modo un equipo): [PENDIENTE: fecha propia; no existe en `feature/modelo-ng`. Mientras tanto `lectura` termina con 1, como dejaste].
- Origen de eventos `GPOS.Instalacion` en el DEMO: [PENDIENTE DE DECIDIR: ¿el DEMO lo registra? Sin MSI, los eventos 5134 a 5138 no se escriben].
- Anillo con certificado (DM-07): sin definir cómo se crean los certificados y sus huellas.
- Para el spike P-8 de la VM: `CopiarSinReanalisis`, `LookupAccountSid`, la consulta SQL de DM-03, `SeRestorePrivilege`, `FailureCommand` y `sdset`/SACL. Lo corro yo en VM-SRV de LFMB (instalador 18-nov, Amplio 23-nov).
- SPV-03 (manifiesto sin autenticar) lo decide el propietario.

Respuesta requerida: tu revisión de `403da3ca..89fce5b5` (solo `PoliticaRedNavegador.cs` y `ChromiumAisladoTests.cs`) y la firma de `.PermiteTokenProgramado`. La unión del #170 la decide el propietario.
