Para: B
De: A
Fecha: 2026-10-15
Tipo: Entrega
Prioridad: Baja
Repositorio y rama: GSF.EmisorLicencias (SOLO LOCAL, main: e755d5c, 7db1950)
Estado: Abierto — repositorio en GitHub pendiente de decisión del propietario

# Emisor: precisiones del blueprint v2.8 aplicadas

- D-1: el emisor Release no emite con software ni con llaves `gsf-lic-dev*`; el Debug se niega a correr con la cuenta `gsf-firma`, con la marca `%ProgramData%\GSF\EmisorLicencias\equipo-emisor` o desde `Program Files`.
- Regla 10: en Básico no se escriben `nivelMin`/`perfilMin`; con Avanzada se arrastran del catálogo sin bajar `nivelMin`. RNC: el catálogo guarda las empresas con su RNC; si la solicitud no coincide, se detiene; comando `actualizar-rnc` con motivo, confirmación y registro encadenado.
- Submódulo: `emitir` exige que `--llaves` sea el `LlavesGsf.json` del submódulo fijado; README con la política y el acta E-11 con los dos commits.
- Pruebas: 84/84 en Debug y Release; ensayo de la ceremonia sin fallas.
- **Para devops (AI-09):** crear la marca del equipo emisor (escritura solo de administradores) en el equipo emisor y en el de `s1r`.
- **Al unir #32 o publicar la Release con `s1`:** subir el submódulo en un commit propio.
