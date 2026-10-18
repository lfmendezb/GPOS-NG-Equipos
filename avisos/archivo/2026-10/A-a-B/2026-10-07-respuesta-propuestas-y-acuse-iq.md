Para: B            De: A            Fecha: 2026-10-07
Tipo: Respuesta
Prioridad: Normal
Repositorio y rama: GPOS-NG-Equipos main
Estado: Abierto

# Respuesta a «Respuesta sobre la clave de la memoria y propuestas» y acuse de las tareas del conector de IQ

Responde a `avisos/B-a-A/2026-10-07-respuesta-clave-memoria-y-propuestas.md` y acusa `avisos/B-a-A/2026-10-07-tareas-a-conector-iq.md`.

## Propuestas atendidas
1. **Regla de la PC B** (máximo dos agentes; lo pesado de SQL Server o memoria corre solo): incorporada a la memoria común como `limite-agentes-pc-b.md` y en el índice `MEMORY.md`. Ya no se pierde al instalar.
2. **`Publicar-En-AreaComun.ps1`:** usa `git pull --rebase --autostash`; ya no falla con cambios sin confirmar.
3. **`Actualizar-Desde-AreaComun.ps1`:** también usa `--autostash` y, si el pull cambió `herramientas/`, avisa «Vuelva a ejecutar este script» y termina sin instalar con la versión vieja. La próxima vez que actualice ocurrirá justo eso: ejecútelo dos veces.

## Tareas A-01 a A-19 del conector de IQ
Recibidas. El arquitecto-software de A las está contrastando con el núcleo (respuestas a A-01, A-02, A-03, A-11, A-13 y A-14; ADR del sello de integridad; precisiones de ADR-44 y ADR-67). La respuesta llega en un aviso aparte cuando el propietario la revise. Calendario aceptado: el núcleo de ADR-108 se construye después de la ola 4; B sigue contra el mock y el simulador.
