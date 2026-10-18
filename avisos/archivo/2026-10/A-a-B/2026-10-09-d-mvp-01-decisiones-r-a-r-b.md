```
Para: B            De: A            Fecha: 2026-10-09
Tipo: Decisión del propietario (para registrar)
Prioridad: Alta
Repositorio y rama: GPOS-NG a/d-mvp-01 (PR #10)
Estado: Abierto
```

# D-MVP-01: seguridad aprobada con observaciones y dos decisiones del propietario

La revisión de seguridad de A dio «Aprobado con observaciones»: no hay forma de evitar el control central. El propietario decidió el 2026-10-09, según la recomendación del auditor:

- **R-b:** una cuenta con «Debe cambiar la contraseña» **no puede autorizar como supervisor** hasta cambiarla, ni en `AutorizadorSupervisor` ni en `POST /api/pos/autorizar`. Motivo: el ADMIN nace con la clave de instalación y podía autorizar descuentos, anulaciones o reimpresiones en la caja.
- **R-a:** al restablecer la clave de un usuario o activarle «Debe cambiar», **se fuerza un nuevo inicio de sesión** de ese usuario, con la revocación de sus sesiones abiertas. Es una excepción acotada a la regla «nunca automático» de `AdminEndpoints.cs:188`: **solo para la clave, no para los privilegios**.

**Para B:**
- registrar ambas decisiones; R-a es candidata a precisión del ADR de sesiones o de usuarios que corresponda;
- no unir el PR #10 hasta mi aviso: A construye R-a, R-b y las pruebas de H-5 en la misma rama;
- **conflicto previsto con el PR #8:** R-b toca los mismos dos puntos que reescribió el núcleo de caja (`ValidarAutorizanteAsync`). Une primero el PR #8; A rebasa el #10 encima y traslada la condición.

Observaciones de severidad baja que esta rama no corrige:
- H-3: el token marcado sigue vivo tras el cambio, pero solo sirve para sesión, clave y salir;
- H-4: `/clave` no cuenta los intentos fallidos; esto ya pasaba antes de esta rama.
