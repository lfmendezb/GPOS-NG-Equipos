```
Para: A        De: B (coordinador)            Fecha: 2026-10-15
Tipo: Respuesta
Prioridad: Alta
Repositorio y rama: área común traspasos/A/hoja-firma-dl01-dl13-licencia-2026-10-14.md (v2.12)
Estado: Abierto
```

# Tercera firma de la hoja de licencia: las DL pendientes, según la recomendación

## Respuesta literal del propietario (2026-10-15, sesión de B)
«Aprobado según la recomendación: Las firmas de licencia DL-01, 02, 03, 05 y las demás de la lista.»

«La lista» es la de pendientes de firma de licencia que B le presentó al abrir la sesión, tomada del traspaso de B del 2026-10-15: DL-01, DL-02, DL-03, DL-05, DL-09, DL-11, DL-12, DL-15, DL-16, DL-18 a DL-22, la regla 3, las P de v2.2 a v2.4, C-5 y la precisión de las cuatro rutas `Esencial` de #35.

## Firmadas, en la opción recomendada de la hoja v2.12
| Punto | Opción |
|---|---|
| DL-01 | **(a)+(b)**: cupo desde el padrón verificado, con copia en `Licencia\padron`; purga y legitimación con los verbos provisionales hasta la fase A de ADR-81 |
| DL-02 | **(a)**: en Release ningún modo sella ni crea cuentas al arrancar (solo `GPOS.Migracion sistema`); con licencia `Produccion` o `Beta`, la API no arranca en Amplio; creación automática solo en `Debug` |
| DL-03 | **(a)**: el RNC solo lo cambia el SUPER; el ADMIN lo ve de solo lectura desde ya; S-03 y S-02 no se publican antes de la fase A de ADR-81; verbos provisionales mientras tanto; con la precisión P-3 (SEG-PR31-01) |
| DL-05 | **(a), obligatoria**: el sello cubre el hash de la contraseña y, en el SUPER, el estado del factor |
| DL-09 | **(a)**: recorte de `autNivel` autorizado con el disparador de 5 días hábiles de atraso respecto de H-3 (precisión de ADR-62, Q-17, si se usa) |
| DL-11 | **(a)** |
| DL-12 | **(a)**: aceptación del riesgo con revisión a más tardar el **2027-03-31**. **La fecha de compra queda por fijar** (es una casilla del propietario; la hoja no recomienda una) |
| DL-15 | **(a)** |
| DL-16 | **(a)** |
| DL-18 | **(a)** |
| DL-19 | **(a)** |
| DL-20 | **(a)**: firma RSA-PSS-SHA256 de cada llave del anillo, API y Web; devops: certificados con `digitalSignature` |
| DL-21 | **(a)** |
| DL-22 (RG-14) | **(a)** con **plazo de 2 min** (la recomendación: 2 min con `ClearPool`; subir hacia 6 si PA-30 muestra 500) |
| C-1 (regla 3 de la §6.1.1) | **Confirmada**: las gracias especiales e `Ilegible` terminan en el corte siguiente |
| C-5 (cuatro rutas `Esencial` de #35) | **Confirmada**: respaldos, cerrar sesiones de una cuenta, resolver el reloj y sincronizar el espejo de numeración siguen permitidos en solo consulta (precisión de ADR-59, punto 6) |
| Precisiones P del blueprint v2.2 a v2.4 | **Aprobadas** |

## Interpretación de B que A debe ver
- **DL-04** no figuraba por nombre en la lista que vio el propietario, pero «DL-01, 02, 03, 05 y las demás» y la hoja la tienen pendiente con recomendación «Aprobar». B la registra como **firmada (a)** y se lo indica al propietario en el mismo turno; si la corrige, B avisa.
- **Siguen pendientes:** C-3 (confirmar), C-2 y C-4 (tomar conocimiento), las aceptaciones escritas de AP-04 (FY-15-B, R-L11-B, CP-4 y CP-5), la fecha de compra de DL-12 y el nombre del custodio suplente (AP-02).

## Efectos
- **#42 (L1b-2):** cae el motivo «apoya en DL-02 sin firma». Siguen los otros tres del rechazo: el interruptor `GPOS:Licencia:Aplicar` (contra ADR-60.6), Estricto sin `InstalacionId` y `/api/super/licencia` retirada mientras la Web la usa. Con DL-21 y C-5 firmadas, `UseLicencia` ya se puede activar en la versión corregida.
- **Desarrollador I:** SL con DL-01 (a)+(b), DL-02 y DL-05; RN con DL-03; la rotación de DL-22 con 2 min; ya no hace falta la marca «PENDIENTE DE FIRMA» en lo que cubren estas DL (DL-16 y DL-05 incluidas).
- **Desarrollador L:** DL-15, DL-18, DL-19 y DL-21.
- **devops:** DL-20 (certificados de la API y de la Web con `digitalSignature`).
- **A, por favor:** actualizar la hoja a v2.13 con el registro de esta firma (sección 7) y preparar las precisiones de ADR que salen de aquí (ADR-58 punto 9, ADR-59 puntos 2 y 6 y NV-07, ADR-62 Q-17 si se usa, ADR-82 por DL-22) y los borradores de ADR-83 y ADR-84 para registrarlos en `master`. B los registra si A lo pide.
