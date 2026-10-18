```
Para: B            De: A            Fecha: 2026-10-10
Tipo: Avance y preguntas para el propietario (por tu conducto)
Prioridad: Alta
Repositorio y rama: GPOS-NG a/h11-desbloqueo-restauracion (42e13b6)
Estado: Abierto
```

# H-11: blueprint listo, preguntas P-1 a P-6 para el propietario

**Blueprint:** `traspasos/A/blueprint-h11-desbloqueo-restauracion-2026-10-10.md`, del arquitecto-software de A.

**Hallazgos en el código:**
- `gpos_app` tiene DENY sobre `sync.EstadoNodo` y `sync.Reconciliacion`, así que el desbloqueo necesita dos procedimientos `EXECUTE AS OWNER`.
- La guarda del servicio rechaza tarde: toma la serie y el NCF, y el 51330 llega después desde los disparadores. Pasará a comparar el fork.
- El 503 menciona «la central».

**Decisiones de diseño:**
- **D-1:** el desbloqueo vale con el rol «ambos», o con «central» si no hay otros nodos activos.
- **D-2:** cada secuencia vigente se cierra en estado `X` en el último NCF probado y el resto del rango pasa a una secuencia nueva. Las secuencias sin diferencias no se tocan (RN-04).
- **D-3:** no habrá subcomando de desbloqueo en `GPOS.Migracion`.
- **D-4:** todo en una sola transacción, en el orden configuración → series → NCF.
- **D-5:** la guarda del servicio compara el fork.

**Contrato:** `GET /api/admin/sitio/restauracion`, y `POST …/vista-previa` y `POST …/desbloquear`, estos dos solo para el SUPER, con un motivo de 15 a 200 caracteres. La pantalla es una tarjeta en Diagnóstico de Numeración. Con DM-02, `verificar` devuelve 0, 2, 3 o 1.

**Esfuerzo:** unas 0,9 sp (de 0,7 a 1,2, inferido), más 0,1 si se aprueba P-3.

**Preguntas para el propietario.** Cada una tiene una opción por omisión y **A avanza con ella** salvo que digas otra cosa:
- **P-1:** ¿se permite un margen voluntario después del último NCF probado? *Por omisión: 0.*
- **P-2:** ¿se adelantan también las series de suplidores y de artículos? *Por omisión: no.*
- **P-3:** ¿este desbloqueo confirma también el siguiente cheque de cada cuenta? *Recomendado: sí (+0,1 sp).*
- **P-4:** en un traslado sin diferencias, ¿se adelantan igual las series? *Por omisión: sí.*
- **P-5:** en las secuencias electrónicas, ¿la única evidencia válida es el proveedor de e-CF? *Por omisión: sí.*
- **P-6:** ¿basta en la entrega 1 con registrar la zona incierta y entregar una guía al contador, sin pantalla para resolverla? *Por omisión: sí.*
- **Aclaración pedida al Maestro:** el registro de H-13 se contradice (la fila dice «Sí» y la cabecera, «pendiente»). El diseño usa **solo el SUPER**, que cumple las dos lecturas.

**Riesgos para tu operación (devops):**
- Un último NCF declarado de menos duplicaría comprobantes. El riesgo es Medio mientras no exista el diario electrónico (H-14).
- **No revertir a paquetes anteriores a H-11:** su respaldo quedaría bloqueado sin forma de desbloquearlo. Conviene dejarlo como regla de operación del DEMO.

**Siguiente en A:** el diseño del esquema (arquitecto-datos), después la construcción.
