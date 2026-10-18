```
Para: A (copia a C)        De: B            Fecha: 2026-10-18
Tipo: Aviso (encargo por firma del propietario)
Prioridad: Media
Repositorio y rama: GPOS-NG; rama a/ nueva sobre feature/modelo-ng @ 322b21d6 o posterior
Estado: Abierto
```

# Encargo: H-L1 y H-L2 (falla cerrada del anillo y de las carpetas fuera de Windows)

**Origen:** la hoja PL-01 a PL-15 (GPOS NG en Linux) la **firmó el propietario el 2026-10-18** en la sesión de C: «Firmo todo según recomendación. Haciendo una precisión sobre el punto PL-10 FIPS/Avanzada elijo la opción (b).» Aviso `C-a-B/2026-10-18-firma-pl-linux`, propuesta en `traspasos/C/propuesta-adr-plataforma-linux-2026-10-18.md`. Con PL-02 (a), desde la firma:

- **H-L1:** sin `GPOS:DataProtection:Carpeta` configurada, el anillo guardaría las llaves sin cifrar fuera de Windows. Debe **fallar cerrado** (la API no arranca) fuera de Windows mientras no exista el equivalente aprobado.
- **H-L2:** fuera de Windows no se comprueban los permisos de las carpetas del anillo ni de la licencia. También **falla cerrado** mientras no exista la comprobación equivalente (vector de ADR-77 para Linux, que vendrá con LN).
- **Costo:** unas 0,05 sp (inferido por el arquitecto de C). En Windows no cambia nada.
- **Pruebas:** dirigidas, más una de arquitectura que demuestre que en Linux, sin el equivalente, el arranque se niega. Revisión de seguridad como siempre.
- **Unión:** la hace B. **No corras suites largas ni cargas en LFMB:** B está midiendo el #61 y el #71 hasta la noche del 2026-10-18.

B registra el ADR de Linux en `master` cuando termine la medición. La costura `ILlaveFirmaTokens` la construye B dentro de D2 de DB-7.

## Para B, después de la medición (anotado aquí para que A lo sepa)
- **#75 (RSV-F1 a F4):** B lo une después de la medición. Antes mira RSVB-02 y RSVB-03, que A dejó para el arquitecto maestro de B.
