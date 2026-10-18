```
Para: B (conocimiento de A)        De: C            Fecha: 2026-10-17
Tipo: Entrega (borradores para registrar)
Prioridad: Media
Repositorio y rama: GPOS-NG-Equipos (traspasos/C); código en GPOS-NG c/adr81-tn-sobre-rn @ d6a1edba
Estado: Abierto: B registra
```

# Entrega: precisión de ADR-83 (TN-01, 7(b) y 7(d)) y adenda de SL-02

Las pidió C a B en `C-a-B/2026-10-17-entrega-tn01-7b-7d`. El propietario encargó a C dejarlas redactadas para que B solo las revise y las registre.

## 1. Precisión de ADR-83
- Archivo: `traspasos/C/propuesta-precision-adr83-tn01-7b-7d-2026-10-17.md`.
- Es un bloque listo para pegar al final de `docs/adr/ADR-083.md`, con el mismo formato que las precisiones RN/SL del 2026-10-17.
- Incluye el texto literal de las dos firmas, la tabla de negativas, los campos de S-01, la precisión de la vía (b) del punto 7 de ADR-81, el SUPER inhabilitado que falla cerrado, el riesgo previo de `--resellar` y las alternativas descartadas.
- Propone además una línea en el índice y una nota de remisión en ADR-81, punto 7.

## 2. Adenda del procedimiento SL-02
- **El procedimiento ya existe:** lo escribió A en `docs/operaciones/2026-10-17-restauracion-gpos-sysdata-cuentas-fuera-del-padron.md` (`a/sl-resellar-candado`, `130306c0`). Por eso C no escribió uno nuevo.
- Archivo: `traspasos/C/adenda-sl02-tn01-7b-7d-2026-10-17.md`. Son seis cambios indicados por sección:
  - el origen;
  - una nota en el paso 2: en una restauración normal, la legitimación del SUPER sigue funcionando;
  - los `campos` de S-01;
  - la sección nueva «Super Usuarios que la legitimación niega»: tabla, vía (b) paso a paso, nivel sin respaldo y lo que queda sin salida;
  - la revisión de los SUPER antes de `--resellar` y «nunca subir a SUPER por SQL»;
  - las filas de pruebas.
- Se aplica al unir T-n, porque describe un comportamiento que solo existe en `c/adr81-tn-sobre-rn`.

## Una decisión para B
En «Nivel sin respaldo», la salida firmada en 7(d), que es también la del mensaje del código, es devolver el nivel anterior. Hoy eso solo se puede hacer por SQL. La adenda lo nombra como **única excepción** a «No edite `dbo.Usuarios` por SQL», con acta y solo para **bajar** el nivel. Si B prefiere no escribir esa excepción, la alternativa es un verbo de `GPOS.Migracion`, que no existe (unos 0,2 dp estimados), y llevarla a la hoja del propietario.

## Sin cambios
- En el repositorio GPOS-NG: no se tocó código ni ramas.
- Lo que sigue pendiente de T-n: la suite oficial (B o A) y el PR, con la nota de unión de TN-06 en el #57.
