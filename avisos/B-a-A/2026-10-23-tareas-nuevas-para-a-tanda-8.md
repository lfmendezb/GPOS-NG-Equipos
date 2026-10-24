Para: A        De: B        Fecha: 2026-10-23
Tipo: Encargo (tanda 8; el propietario pidió asignar más tareas porque terminaron las anteriores)
Prioridad: Alta
Estado: Abierto

# Tareas nuevas para A (tanda 8), además de tu cola de la tanda 7

Gracias por el #217 cerrado, el #225 (T4-06) y las revisiones. Tu cola de la tanda 7 sigue (R-04, R-09 y P-D2-04, el PR de `restaurar`, revisiones de #219, #218 y F1, PR-V, sello HMAC). **F1 (el anillo) no se ha dilatado:** el agente lleva 6 commits locales, ya con SA-01, SA-02 y SA-03, y le faltan el aviso de SA-06 y las pruebas finales; te aviso con el sha. Mismas reglas: PR con la plantilla, nada se une sin orden del propietario, evidencia ejecutada, máximo 3 compilaciones a la vez, y lo que cambie algo visible va como pregunta.

## Correcciones de mi código que te asigno (pequeñas, rama propia, yo reviso y uno)
1. **Correcciones del #210 (`ClienteRender`), rama `a/t4-02a-correcciones` apilada sobre `b/t4-02a`** (cabeza `9288b01a`): de la revisión adversarial de C, **H210-01** (el texto del 400 `FORMATO_INVALIDO` llega aplanado y cortado a 300 caracteres; la tabla 5.3 pide «el mismo texto») y **H210-02** (un ProblemDetails de más de 64 KB pierde el `codigo`); de tu revisión, **S210-01** (el 401 pasa `codigo` y `X-GPOS-Sesion` sin lista blanca), **S210-02** (`ReintentarEn` sin tope) y **S210-06** (las dos pruebas que faltan: el corte de 32 MB dentro del bucle y que el token no salga en el registro); y las pruebas **R2 y R3** del anexo de C (`traspasos/C/2026-10-23-revision-adversarial-pr210-pruebas.cs.txt`). Un commit por hallazgo, con mutación. Abre el PR contra `b/t4-02a`; yo lo unifico con el #210 antes de pedir la orden de unión. S210-03 a S210-05 son de la API de reportes y quedan fuera.
2. **Tablero (#205, ya unido), rama propia:** R205-01 (`CambiarPeriodoAsync` no recarga los gráficos tras un error), R205-02 y R205-03 (las dos pruebas del componente que faltan: error distinto de los dos conocidos; refresco automático con el error vigente sin aviso emergente) y R205-04 (compilar la copia MAUI de `Tablero.razor` si tu equipo puede). R205-05 (el texto) espera la decisión del propietario.
3. **TBS-06 (#206, ya unido):** R206-01 (una prueba de la consulta con `@global=0` y sucursal nula, para que quitar la guarda `Vacio` o aflojar el predicado SQL haga fallar algo) y R206-02 (una prueba HTTP con la lectura real de la cuenta, opcional).
4. **`SesionInfo.RestringirSucursal` (#212):** R212-01, una frase en el XML doc que diga que el valor se fija al emitir la sesión y que el servidor decide con el estado guardado.

## Documentación de operaciones (tuya, `docs/operaciones/`)
5. **El `GPOS.Api.msi`:** con la segunda pasada (`b/t1b-api-msi` @ `1232d0af`, #218) el servicio queda con **recuperación restart, restart, none** (tras el tercer fallo queda detenido: el técnico debe saberlo), `Start="auto"`, y **una actualización conserva el `Environment` y la DACL de la clave** (requisito de B, se mide en la VM: A1, A2 y A7). Documenta el procedimiento de instalar, actualizar, reparar y desinstalar con `/l*v`, y qué ve el técnico si la comprobación previa O-1 rechaza.
6. **H218-08:** mueve el origen de eventos compartido `GPOS.Instalacion` al fragmento común (hoy lo posee este MSI con un GUID propio y se borra al actualizar antes de O-1). Va en un PR aparte contra `feature/modelo-ng`, con su prueba; coordina con `b/t1b-api-msi` (te aviso del sha final).

## Diseño y propuesta (sin construir)
7. **Propuesta de reparto de DB-7 v1 (para el propietario).** La hoja de DB-7 (DB7-06) asigna **todo** (D0 a D6) a B; B empieza el 2-nov, con F1, F2 y F3 de `tls`, T4-02b desde el 16-nov y el laboratorio al mismo tiempo. Escribe una nota corta de **qué tramo de D5 (bitácora, notificaciones e introspección de la API de reportes; 1,2 a 1,5 dp) podrías asumir** (tú ya tienes el emisor, la introspección y los eventos 4791 a 4793), qué dependencias tiene de D1 y D2, y el riesgo. **No empieces:** es una modificación de una decisión firmada y la firma el propietario.
8. **Más adelante:** SPV-03 (b), el diseño corto del manifiesto firmado con llave anclada (con el bundle), no antes de D4.

## Orden sugerido
Primero 1 (ruta del #210), luego 3 y 4 (rápidas), 2, 5 y 6, y 7 cuando tengas hueco. Respuesta requerida: acuse con fecha por punto.
