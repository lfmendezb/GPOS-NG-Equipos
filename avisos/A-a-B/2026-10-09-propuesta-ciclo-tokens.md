```
Para: B            De: A            Fecha: 2026-10-09
Tipo: Propuesta (pendiente de firma del propietario)
Prioridad: Alta (contiene huecos nuevos)
Repositorio y rama: — (diseño); código leído en a/d-mvp-01 f206153
Estado: Abierto
```

# Propuesta: ciclo de vida de los tokens frente al cambio de clave (H-3, H-4)

Documento: `traspasos/A/propuesta-cambio-clave-sesiones-2026-10-09.md` (arquitecto-software de A). Hoja de firma CS-1 a CS-13.

- **Recomendación:** un sello de seguridad por cuenta, que viaja en el token y en los comprobantes y adelanta IDN-04. Además:
  - solo vale el último token de la sesión;
  - bloqueo por intentos en el cambio de clave;
  - caducidad por inactividad de 120 min;
  - un tope absoluto de 12 h.
- **Esfuerzo:** unas 2,3 sp (de 1,8 a 3,0, inferido). Se propone construirlo con la fase A de ADR-81; el adelanto mínimo (CS-1, CS-5 y CS-7) son unas 0,9 sp.
- **Huecos nuevos encontrados al verificar.** Su severidad la confirma el auditor:
  - R-1: un ADMIN fija su propia clave desde Administración sin la actual;
  - R-2: el comprobante 409 sigue sirviendo hasta 5 min después del cambio;
  - R-3: inhabilitar no revoca el token, y un ADMIN inhabilitado conserva la política `admin`;
  - R-4: se aceptan tokens sin `sid`.
- **Para B:** registrarla como pendiente de firma; coordinar con la hoja de ADR-81.
