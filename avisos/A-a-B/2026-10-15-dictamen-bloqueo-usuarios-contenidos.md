```
Para: B        De: A                          Fecha: 2026-10-15
Tipo: Entrega
Prioridad: Media
Repositorio y rama: área común traspasos/A/revision-seguridad-bloqueo-usuarios-contenidos-2026-10-15.md
Estado: Abierto
```

# Dictamen: la política de bloqueo no se aplica a los usuarios contenidos (Confirmada)

## Veredicto
- **Confirmada, según la documentación.** Lo dicen cinco fuentes de Learn que coinciden; las URL están en el dictamen.
- **Qué se aplica a los usuarios contenidos:** la complejidad de la contraseña sí; la caducidad, el historial y el bloqueo no.
- **2022 y 2025:** el comportamiento es el mismo. Lo único que cambia es el hash: en 2025 es PBKDF2, con más costo de CPU por cada intento fallido.
- **Falta la prueba real:** no se probó en una instancia, porque la contención está en 0. La prueba la hace QA en una instancia desechable cuando se aplique A-N4.
- **D-04 (a) puede apoyarse en esta suposición.**
- **Recomendación técnica:** Aprobado con observaciones; ningún hallazgo Crítico ni Alto abierto.

## Hallazgos
| ID | Severidad | Hallazgo |
|---|---|---|
| BL-01 | Media (Alta si se construye así) | Un login SQL de servicio con la política activa se bloquea con unas 5 peticiones fallidas, porque `NeverBlock` y la reapertura hacen 2 intentos por petición. Hoy no existe ninguno. |
| BL-02 | Media | Sin bloqueo, nada frena los intentos en línea contra el puerto de SQL, porque K1 solo frena HTTP. No hay alerta del error 18456. |
| BL-03 | Media (Alta en un cliente) | `gsf` está con `CHECK_POLICY = OFF`, contra ADR-44 AC-1. Ocurre en las dos instancias de la PC A. |
| BL-04 | Baja | La contraseña generada puede incumplir la complejidad (1 de cada 7.600). Falla sin dañar nada. |
| BL-05 | Baja | Un usuario contenido con el mismo nombre que un login le impide la entrada a ese login. |
| BL-06 | Baja (sospecha) | Al restaurar una copia anterior a una rotación vuelve la contraseña vieja y aparece el error 18456 hasta correr `credencial-app`. Hay que confirmarlo con el dueño de H-11. |

## Remediaciones y dueños
- **Desarrollador I** (sigue en la cola de A, junto con DL-02 (a)):
  - **R1:** en S0, `CHECK_POLICY = OFF, CHECK_EXPIRATION = OFF` explícitos, solo en la variante S.
  - **R2:** `LOGIN_SERVICIO_CON_POLITICA`, `LOGIN_ADMIN_SIN_POLITICA` y `CONTENIDO_DUPLICA_LOGIN` en `verificar`.
  - **R6:** la contraseña generada cumple siempre la complejidad.
- **Maestro** (en curso): **R3** a la hoja de PUB-06 (M5 corregido, M5-b y M5-c), más R4 (puerto de SQL), R5 (alerta del 18456) y la precisión de ADR-44 y ADR-82.
- **Propietario:** `gsf` con `CHECK_POLICY = ON` (BL-03). Queda pendiente de su decisión.
