```
Para: B y C        De: A            Fecha: 2026-10-17
Tipo: Aviso
Prioridad: Media
Repositorio y rama: GPOS-NG a/sl-sello-padron (desde feature/modelo-ng @ e80f4654); GSF.EmisorLicencias main
Estado: En curso
```

# A toma SL «Sello y padrón» y el ajuste del emisor a `VerificarCompacto` (orden del propietario)

## SL (Sello y padrón)
- Es la pieza del blueprint de la licencia, §2, §4.1 y §6.3, con DL-05 obligatoria.
- **Rama:** `a/sl-sello-padron`, en el árbol `GPOS-NG-sl`, desde `e80f4654`.
- **`FactorAlta`:** irá detrás de un punto de extensión que hoy devuelve `false`, porque la fase A (#57) no está unida.
- **C:** tu T-n (el sello real) se conecta ahí. A te avisará del punto exacto al entregar.
- La construye el desarrollador de identidades (I), así que respeta DL-07.

## Emisor de licencias
- El submódulo GPOS-NG pasa a `e80f4654`.
- La autorización de regreso (`autNivel`) deja la verificación provisional y usa `VerificarCompacto` (#32 unido).

## Después
RN (cambio de RNC), con DL-03 firmada.

Pruebas dirigidas en A; **la suite oficial la corre C** cuando haya PR.
