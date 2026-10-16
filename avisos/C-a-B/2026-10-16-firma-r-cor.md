```
Para: B y A        De: C            Fecha: 2026-10-16
Tipo: Aviso
Prioridad: Alta
Repositorio y rama: GPOS-NG-Equipos traspasos/C/hoja-firma-recuperacion-super-2026-10-16.md; registro en el PR #53
Estado: Abierto
```

# Firma del propietario: recuperación del SUPER con una autorización firmada por GSF (vía a′)

**La firma.** El propietario firmó el 2026-10-16, en la sesión de C: «Firmo R-COR-01 (D), R-COR-02, R-COR-03 y R-COR-04 según la recomendación». La hoja está en `traspasos/C/hoja-firma-recuperacion-super-2026-10-16.md`.

## Qué decide
**R-COR-01 (D): vía (a′).** GSF identifica a su agente y emite un JWS `autRecuperacionFactor`. Sus condiciones:
- va ligado a la instalación y al usuario;
- dura 24 h como máximo;
- lleva un `jti` de un solo uso.

**Cómo se usa:**
- El SUPER lo pega en la Web junto con su contraseña.
- Eso abre una sesión restringida solo al alta del factor.
- Todos los SUPER reciben un aviso y queda un evento de severidad `A`.

**Lo que no hace:**
- La instalación no envía ningún correo; GSF puede entregar la autorización por correo.
- Sirve en Básica y en Avanzada.
- No reabre el descarte del correo de ADR-81.

**R-COR-02:** el orden de las vías queda así: códigos de respaldo → (a) otro SUPER → (a′) GSF → (b) comando. El comando sigue cubriendo el olvido de la contraseña.

**R-COR-03:** la guía y la prevención:
- dos dispositivos al dar de alta el factor;
- los códigos de respaldo guardados fuera del teléfono;
- el aviso P-81A-07 en la portada.

**R-COR-04:** un formato único para las autorizaciones de GSF, el mismo para (b+), el punto 11 y (a′).

**Lo que precisa:** ADR-81 (punto 7, punto 12 y una nota en las alternativas descartadas) y ADR-59, punto 6 (la ruta restringida es Esencial). No hace falta un ADR nuevo.

## Siguientes pasos
1. **Registro:** C lo agrega al PR #53 (`master`). **B:** no lo registres por tu cuenta.
2. **Revisión de seguridad:** el auditor de C revisa la sección 4 de la hoja y R-4 (que la sesión restringida no alcance ninguna otra ruta).
3. **Diseño y construcción:** T-j2 entra en el blueprint v4.1 y se construye después de T-j y T-m. Va como última tanda de la fase A si cabe antes del corte, o en la fase B junto con (b+). **No retrasa la unión de la fase A.**
4. **Emisor de GSF:** necesita el tipo nuevo `autRecuperacionFactor`, con el formato común. Está fuera de este repositorio.
