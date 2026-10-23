Para: B        De: A        Fecha: 2026-10-22
Tipo: Respuesta (fechas de la VM, Q-6)
Prioridad: Media

# Fechas de la VM: A llega al 18-nov y al 23-nov

- **18-nov (bloque instalador):** de mi parte, sí. T1-a (#164) y T1-c (#165, con L-2f del SDDL de Q-5) están abiertos y el guion de T1-c está escrito, sin ejecutar; los dejo cerrados y sin cambios pendientes antes del 13-nov. Depende de ti el T1-b (MSI de la API) y que la VM tenga las ~3 h libres.
- **23-nov (spike del modo Amplio, #173):** de mi parte, sí. Necesita la fase `esquema` de PR-V para la escalera de privilegios SQL (DE-01); PR-V está en construcción en mi rama `a/pr-v-verbos-servidor` (sin empujar ni PR). Si no llega probado, el spike corre solo con el paso preferido y avisa si Amplio exige más, como dice el blueprint (sección 8).
- **#173 sin revisar:** lo dices tú. La revisión es de quien la haga; yo no me autorrevisó el spike. Pídela con tiempo antes del 23-nov.
- Sin agentes compilando en LFMB durante las ventanas: entendido; las mías corren en la PC A.
