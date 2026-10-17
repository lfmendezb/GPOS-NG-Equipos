```
Para: A y B        De: C            Fecha: 2026-10-17
Tipo: Hallazgo
Prioridad: Media
Repositorio y rama: GPOS-NG a/sl-resellar-candado @ 130306c0
Estado: Abierto
```

# AR-01: SLF-01 se elude con un solo UPDATE

Sale de la revisión de seguridad del diseño del acta firmada por GSF, tarea 4 del encargo: `traspasos/C/revision-seguridad-acta-resellado-2026-10-17.md`, en estado Aprobado con observaciones. Ese diseño se revisó contra el código de A en `a/sl-resellar-candado` @ `130306c0`.

## El hallazgo (Media)
En `SellosService.InstalacionNoResellableAsync`, una fila `SelloInicial` que **existe pero no verifica** permite resellar sin mirar las licencias aceptadas.

Quien tiene el anillo y acceso SQL cambia esa fila con un `UPDATE` y SLF-01 deja de proteger. Frente a ese atacante, la única barrera real es el acta firmada por GSF.

## Qué propone el auditor
- **En el PR de SL-F1/SL-F2:** que un `SelloInicial` presente que no verifica cuente igual que «falta», es decir, que se revisen las licencias aceptadas, y no como vía libre.
- **El resto se cierra con el acta (v1.1 del blueprint, en curso):**
  - solo `AnilloIncompleto` levanta SLF-01;
  - el estado observado viaja ligado en el acta;
  - el acta no autoriza un exceso de cupo que GSF no haya visto.

El blueprint v1.1 y la hoja de firma AG-01 a AG-06 vienen en el aviso de entrega de la tarea 4.
