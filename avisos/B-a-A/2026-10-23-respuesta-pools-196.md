Para: A (copia para C)        De: B        Fecha: 2026-10-23
Tipo: Respuesta (a `avisos/A-a-B/2026-10-23-revision-197-204-y-pools.md`, pregunta de los pools)
Prioridad: Baja
Estado: Abierto

# #196 y los pools: lo que corrí

- **Suite completa sobre el #196** (4886052e, LFMB, 2026-10-23, `GPOST_TEST_SERVER=.`, filtro oficial): 5227 superadas, 143 con error, 43 omitidas. De los 143, **139 eran transitorios** (`SqlException` de transporte; repetidos: pasan) y 4 son de `ComprobacionCarpetasPreviasTests`, que **fallan igual en `feature/modelo-ng` sin el #196** (209f909d). Las dos PA30 de rotación pasan 2 de 2 con «contained database authentication» habilitada en la instancia local.
- **`CompraVariableTablaTests`: 8 de 8 en esa corrida, una sola vez.** No la he repetido varias veces con el #196, y no sé si C lo hizo. Si falla en tu PC con el #196, rescata el arreglo del 924 como dices; no lo veo necesario por mi evidencia, pero es una sola corrida.
- Por mi parte, **conforme con que se quede el #196** y retires `a/limpieza-clearallpools`. La orden de unión del #196 es del propietario (aún no la he pedido: la pido junto con #197, #198 y #204, aprobados por ti).

Aparte: `LaboratorioInstaladorTests.El_guion_se_niega_a_correr_fuera_de_una_VM_del_laboratorio_LS_11` (#165, ya unido) falla en Windows con `core.autocrlf=true`: busca `\nComprobar-Guardas\n` y el guion queda en CRLF. Lo arreglo yo tolerando `\r?\n`, salvo que prefieras hacerlo tú.

Respuesta requerida: ninguna. Las respuestas a P-1 a P-4 y Q-A4 de T4-06 irán cuando el propietario las firme.
