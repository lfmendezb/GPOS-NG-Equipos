# Blueprint corto: `implantar-servidor --fase restaurar` (PR-D2, reversión de binarios con servicios)

Estado: **Propuesto por A, sin código.** Rama de destino: `a/pr-d2-manifiesto` (sobre PR-V `a3c71ce1`). Pide el OK de B (y la firma que el contrato del verbo exija).

## 1. Para qué
`Revertir-Actualizacion.ps1` se niega hoy con servicios (DM-08: la copia previa protegida `.anterior` no tiene quién la restaure). Además, `FaseServicios` deja el destino mezclado si queda la marca `.aplicando` y manda a «restaurar a mano»: la fase nueva es la vía autorizada para eso también.

## 2. Contrato
`implantar-servidor --perfil demo --fase restaurar [--destino <ruta>]`
- Solo perfil demo (producción: «aún no implementado», como `servicios`). Sin `--origen`, `--rotar-jwt` ni `--usuario-instala`: no lee paquetes ni toca configuración.
- Precondiciones (todas, antes de escribir; si falla una, **Detenida** sin cambios): carpetas de datos presentes (`FaseCarpetas` sin crear); destino normalizado y seguro (las guardas de `PrepararDestino`); **ningún ejecutable en marcha** (`EjecutableEnMarcha`); `.anterior` existe, es segura (`ReglasDescriptores.MotivoCarpeta`: dueño, reanálisis, escritores) y trae su `manifiesto.sha256`.
- Efecto: cada archivo de `.anterior` se copia al destino; los archivos de `app\api` y `app\reportes` del destino que no estén en el manifiesto de `.anterior` se borran (los que añadió la versión nueva); las huellas se verifican **en el destino** contra el manifiesto de `.anterior`. Misma marca `.aplicando` que la copia (ver 4).
- No toca: servicios, cuentas, SDDL, entorno, clave JWT (las sesiones no se cierran), orígenes de eventos ni bases. Repetirla es idempotente (huellas iguales: «al día»). `.anterior` no se borra.
- Códigos de salida y eventos: los existentes (`Hecho`, `Detenida`, `Fallida`) más un evento nuevo **5140 `ServidorBinariosRestaurados`** (franja 5130-5149 del instalador; 5130-5139 en uso; verificar con `git grep` en todas las ramas antes de fijarlo). Sin rutas de usuario ni mensajes de excepción en los eventos.

## 3. Cambio necesario en la copia (integridad de `.anterior`)
Hoy `.anterior` no tiene huellas propias: restaurar desde ella confiaría en su contenido. Cambio en `CopiarBinarios`, paso 2: tras la copia previa, escribir `.anterior\manifiesto.sha256` con las huellas de lo copiado (formato del paquete), calculadas al copiar y comparadas con las del destino antes de copiar. Si el destino ya difería de su paquete (alteración previa), la copia se hace igual pero el manifiesto lo marca `no-verificada` y la fase `restaurar` se detiene con ese motivo. *Decisión abierta Q-R1.*

## 4. Amenaza (STRIDE resumido)
| Amenaza | Control |
|---|---|
| Manipular `.anterior` para plantar binarios que correrán como servicio | DACL `SddlServicios.CopiaPrevia` (solo SYSTEM y administradores), `MotivoCarpeta` al entrar, huellas del manifiesto de `.anterior` verificadas **antes** de copiar y **en el destino** después. Un administrador local ya puede reemplazar los binarios: el control cubre el cambio de dueño o reanálisis y el error, no a un administrador hostil. |
| Vínculos simbólicos o puntos de reanálisis dentro de `.anterior` | Copia con `CopiarSinReanalisis` (la de la preparación), no `CopiarArchivo`; cualquier reanálisis detiene. |
| Restaurar con el servicio en marcha o con estado mezclado | `EjecutableEnMarcha` detiene antes de escribir; la marca `.aplicando` se crea antes del primer archivo y se borra solo si todo verifica; si existe al entrar, `restaurar` **reanuda** (es la única fase que puede, porque `.anterior` es la copia íntegra) y `servicios` sigue negándose. |
| Restaurar binarios que no corresponden al esquema de la base | Fuera de la fase: lo decide el guion (base y programas vuelven JUNTOS; sin `-RestaurarBases` no se llama a la fase). La fase no lee bases. |
| Repudio | Evento 5140 con cantidad de archivos y huella del manifiesto, sin rutas de usuario; el guion anota `revertida` en `actualizacion.json`. |
| Fuga de información | Sin secretos: la fase no lee ni escribe el entorno. |
| Denegación (disco lleno, `.anterior` vacía) | `.anterior` vacía o sin manifiesto: Detenida sin cambios; la copia es archivo a archivo con restauración parcial reportada, como `Restaurar` hoy. |

## 5. Guion (`Revertir-Actualizacion.ps1`, modo Servicios)
Mantiene el aviso DM-01 y la confirmación `RESTAURAR`. Orden: Detener-Demo, restaurar bases (con `-RestaurarBases`, como hoy), `implantar-servidor --fase restaurar`; si la fase no da Hecho, **no** se inician los servicios y se dice por qué; después `comprobar-servidor --perfil demo --sin-red` y la anotación en `actualizacion.json`. Solo se puede revertir la **última** actualización (`.anterior` es de un solo nivel); otra marca se rechaza con ese motivo (Q-R2).

## 6. Pruebas (en `ImplantarServidorTests`, con el doble de `ISistemaServidor`; cada una con su mutación en rojo)
1. Restaura los archivos cambiados, borra los añadidos y respeta los demás; huellas iguales al manifiesto de `.anterior`.
2. Idempotente: segunda pasada, «al día», sin cambios.
3. Servicio en marcha: Detenida, destino intacto.
4. Sin `.anterior`, vacía, sin manifiesto, `no-verificada` o con huella distinta: Detenida o Fallida, destino intacto.
5. `.anterior` con dueño ajeno, escritor extra o reanálisis: Detenida (las guardas del destino).
6. Reanudar con `.aplicando`: restaura y borra la marca; `servicios` con la marca sigue negándose.
7. Fallo parcial al copiar (excepción en el 2.º archivo): se informa cuáles y la marca queda.
8. No toca servicios, entorno ni clave JWT (el doble registra cero escrituras).
9. Perfil producción: «aún no implementado»; `--origen` o `--rotar-jwt` con `restaurar`: error de opciones.
10. Eventos: 5140 solo en éxito y sin rutas de usuario.
11. Guion: en modo Servicios llama a la fase solo con `-RestaurarBases`, no inicia servicios si la fase no da Hecho y rechaza una marca que no es la última.
12. `ServidorArquitecturaTests` sigue en verde (la fase no referencia la API ni EF).

## 7. Esfuerzo y orden
≈ 1,0 dp (fase y cambio de `CopiarBinarios` 0,5; guion 0,2; pruebas 0,3). Independiente del anillo y de `tls`. Revisión de seguridad antes del PR; no se une sin orden del propietario.

## 8. Decisiones que se piden a B
- **Q-R1:** ¿el cambio de `CopiarBinarios` (manifiesto en `.anterior`) va en PR-D2 o en PR-V? A recomienda PR-D2, porque PR-V ya está revisado. Y con una copia `no-verificada`, A recomienda detenerse sin opción de forzar en el DEMO.
- **Q-R2:** ¿basta una sola marca revertible (la última) para el DEMO? A recomienda que sí.
- **Q-R3:** ¿una fase nueva del verbo necesita hoja de firma del propietario o basta el OK de B?
