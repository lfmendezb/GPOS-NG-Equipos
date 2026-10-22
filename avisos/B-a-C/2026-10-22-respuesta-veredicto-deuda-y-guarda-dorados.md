Para: C        De: B        Fecha: 2026-10-22
Tipo: Respuesta (a el veredicto de la deuda P137/P140 y a la entrega de la guarda de los dorados)
Prioridad: Media
Repositorio y rama: GPOS-NG `b/deuda-pr2-p137-p140`; `c/dorados-guarda-t4-01`
Estado: Abierto

# Respuestas al veredicto de la deuda y a la guarda de los dorados

El propietario autorizó subir la deuda al #140 (la sube A) y unir #137, luego #139 y #140 juntos.

## Veredicto de la deuda
- **Aceptada** la deuda de P140-01 y P140-02 para el laboratorio (TL-01, TL-02 y TL-03 opcional), en la VM de LFMB. Los hallazgos Bajos nuevos quedan de seguimiento; los que toquen producción los decide A (P140b-01: sin EventId, A dijo que no lo necesita).
- **Tus preguntas:** las 3 pruebas omitidas son las de Kestrel real con `GPOST_PRUEBA_ESCUCHA_RED=1` y la de P140-01 se omite si el equipo no tiene certificados; en mi PC (LFMB) hay 4 certificados en `LocalMachine\My`, así que P140-01 **corrió**. Corro solo el quinto caso de la mutación de P137-04 (`http://[::]:443`) y te digo el resultado.

## Guarda de los dorados (D-1 a D-4)
- **D-1:** versiones **estrictas** (como está). Subir QuestPDF o Razor exige una corrida deliberada con motivo, y deja entrada en `CAMBIOS.md`.
- **D-2:** manifiesto en **JSON** (como está).
- **D-3:** el modo `linea-base` se **borra tras unir** (es de un solo uso y reduce la superficie); queda registrado en `CAMBIOS.md`.
- **D-4:** «falla cada caso recapturado» es suficiente.
- **Archivo compartido:** `RenderInternoTests.cs` lo tocó mi agente (P152-01/04/05, ya empujado en `cf6ccf98`) y tu PR (P152b-03): rebasa tu PR sobre `b/ola5-t4-01-render` y yo no lo toco hasta tu aviso.
- **Captura de los grupos 1 a 6:** tú escribes el código por grupos con pruebas dirigidas; **B corre la captura en LFMB** y te devuelve los dorados. D-25 y D-26 esperan a A.

## Tarea nueva
- **Verificar `Inhabilitado`:** tu hallazgo (ninguna ruta pone `cat.Cliente.Inhabilitado = 1`) y que un cliente inhabilitado no se valida al cobrar son para decidir en TT. B los lleva al propietario; no hace falta acción tuya.

Respuesta requerida: ninguna salvo la prueba de la guarda cuando tu PR esté rebasado.
