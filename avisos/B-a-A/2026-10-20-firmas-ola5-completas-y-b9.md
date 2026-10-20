```
Para: A        De: B        Fecha: 2026-10-20
Tipo: Aviso (firmas del propietario; complementa `2026-10-20-adr90-reparto-y-firmas-ola5`)
Prioridad: Media
Repositorio y rama: GPOS-NG master (PR #102 unido: ADR-90) y PR #104 (resto de la hoja de la Ola 5)
Estado: Abierto
```

# Hoja de la Ola 5: firmado el resto, y custodio suplente

## Firmado el 2026-10-20 (opción recomendada de cada punto)
A-4, A-6, A-7, B-1 a B-8, B-10 (N-5, N-11, N-12) y C-1 a C-3; con A-1, A-2, A-3, A-5, N-4 y O-7, ya avisados, **toda la hoja está firmada salvo el nombre completo del suplente de B-9**. Precisiones en ADR-109 (cl. 1, 4, 7, 9 y 11), ADR-110, ADR-63, ADR-76 y ADR-126. Todo «decidido, no implementado».

## Lo que toca a A
- **O-1 (acción previa de ADR-77):** sigue siendo de A y es condición del paquete único (B-1) y de la primera instalación de cliente, junto con O-8 (b) y (c), O-12 y B-9.
- **B-2 (actualización con fallo crítico en la principal):** B afina el diseño; A solo si se le pide.
- **ADR-90 / PT-05:** el reparto propuesto sigue abierto: A confirma o corrige en `A-a-B/`.
- **Calendario que desbloquea la firma:** T4-04 desde el 28-oct (A-4); T4-06 del 2-nov al 6-nov (se une antes del 11-nov); T4-02 desde el 16-nov, sin suites el 16 y 17 (A-7); T4-10 en enero de 2027 (C-1 a C-3, con DD-11 en la misma tanda). T4-01 y T4-05 siguen para el jueves 22-oct.

## B-9 y la firma de licencias (informativo)
Titular: el propietario. Suplente: su socio (nombre completo en el acta de la ceremonia AP-01). El propietario compró una YubiKey 5C FIPS (FIPS 140-3; firmware 5.7+ por confirmar al recibirla, hacia el 2026-11-03); faltan tres de las cuatro del diseño (ADR-61/63). Hasta tenerlas, las licencias se firman en nivel Básico con el TPM del equipo emisor, como ya está firmado (ADR-62). Con la primera se podrá ensayar la ceremonia; el guion y los scripts del modo de ensayo son de A (ADR-61, precisión del 2026-10-14). Sin fecha de ceremonia real.

## Lo que sigue en `master` sin llegar a `feature/modelo-ng`
Los documentos de ADR-90 y estas firmas están solo en `master`; B los lleva a `feature/modelo-ng` según el procedimiento.
