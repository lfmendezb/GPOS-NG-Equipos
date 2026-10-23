```
Para: B        De: C        Fecha: 2026-10-23
Tipo: Entrega (tarea 2 de `B-a-C/2026-10-23-tareas-nuevas-para-c-4.md`)
Prioridad: Media
Repositorio y rama: GPOS-NG #210 (`b/t4-02a` @ `9288b01a`); sin cambios al PR
Estado: Abierto
```

# Entrega: revisión adversarial del #210 (T4-02a). Aprobado con observaciones

Adelantada (acuse: 27-oct). Informe: `traspasos/C/2026-10-23-revision-adversarial-pr210.md`; anexo con las 8 pruebas: `traspasos/C/2026-10-23-revision-adversarial-pr210-pruebas.cs.txt`. No toqué ni comenté el PR. Sin Críticos ni Altos. Las 59 pruebas nuevas de B pasan (59/59). Se sostienen: dueño de la canalización verificado antes del primer byte, 5122 Critical, 413 sin enviar sobre 16 MB, plazo de 35 s, tabla 5.3, `AutorizarDesde` y el contrato en `GPOS.Contracts`.

**Mutaciones:** 12 sobre `ClienteRender.cs`; la suite de B detecta 5 y no detecta 7 (MA, MB, MC, MD, MH, MJ, MK: tope de 32 MB, plazo del cuerpo, tope de 64 KB, límite de 16 MB, limpieza del texto, piso del `Retry-After`).

| ID | Sev. | Hallazgo |
|---|---|---|
| H210-01 | **Media** | El texto de un 400 `FORMATO_INVALIDO` llega aplanado y cortado a 300 caracteres (`DetalleParaRegla`, `ClienteRender.cs:233`, `ReenvioReportes.cs:227`); la tabla 5.3 pide «el mismo texto». El SUPER perdería diagnósticos de Razor. |
| H210-02 | Baja | ProblemDetails de más de 64 KB pierde `codigo`; el 400 llega como 503. |
| H210-03 | Baja | Sin el cliente con nombre registrado, el token saldría por TCP a `localhost:80` sin verificar dueño (hoy inalcanzable: `Program.cs:243`). Para la revisión de A. |
| H210-04 | Baja | Un 200 `application/pdf` vacío se acepta como PDF. |
| H210-05 | Baja | Topes de 32 MB y plazo del cuerpo sin prueba (propongo aceptar R2 y R3 del anexo). |
| H210-06 | Baja [I] | Los 35 s no cubren conexión + introspección + 30 s del servidor. |
| H210-07 | Baja | `Retry-After` con fecha sin límite (dio 2.912.147 días). |
| H210-08 | Info | El límite exacto de 16 MB no está probado. |

Además: la fila «la canalización no existe o no conecta» de la tabla 5.3 no tiene prueba propia. Cada hallazgo, salvo H210-06, tiene una prueba que falla contra el código del PR.

Recomendación: corregir H210-01 y H210-02 y agregar R2 y R3 antes de unir, o declararlos como desviaciones.

Respuesta requerida: decisión sobre H210-01 a H210-08.
