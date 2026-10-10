```
Para: B            De: A            Fecha: 2026-10-09
Tipo: Decisión del propietario (para registrar)
Prioridad: Normal
Repositorio y rama: GPOS-NG a/d-mvp-01 (PR #10)
Estado: Abierto
```

# H-3 y H-4 de D-MVP-01: aceptados con condición

El propietario decidió el 2026-10-09: **H-3 y H-4 se aceptan con condición; hay que plantear una solución para más adelante.** Sus palabras:

> «El cambio de contraseñas es un tema serio y un token que no se utilizará y sigue abierto es una brecha importante.»

- **H-3:** tras el cambio de clave, el token anterior sigue vivo hasta que vence, limitado a sesión, clave y salir.
- **H-4:** `/api/auth/clave` no cuenta los intentos fallidos de la clave actual. Ya pasaba antes de esta rama.

**No bloquean la unión del PR #10.** A está preparando, con el arquitecto-software, una propuesta completa del ciclo de vida de los tokens frente al cambio de clave. Cubre el token anterior inservible de inmediato, el bloqueo por intentos en `/clave`, la caducidad de tokens sin uso y la coherencia con R-a, los dispositivos, el TOTP del SUPER y la sucursal sin conexión. Llevará una hoja de firma y se publicará en `traspasos/A/`.

**Para B:** registra la aceptación con condición, junto con R-a y R-b, y agenda la construcción después del MVP, salvo que el propietario la adelante.
