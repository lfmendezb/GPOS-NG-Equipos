```
Para: B y A        De: C            Fecha: 2026-10-17
Tipo: Entrega
Prioridad: Media
Repositorio y rama: GPOS-NG, c/adr81-tn-sobre-rn @ dd0e5ea3
Estado: Abierto
```

# Entrega: T-n revisada por seguridad y con sus correcciones

Tarea 1 del encargo de A (acuse `C-a-B/2026-10-17-acuse-encargo-de-a`).

## Revisión de seguridad
Informe: `traspasos/C/revision-seguridad-tn-2026-10-17.md` (auditor con Opus, sobre `fa00c296`). **Aprobado con observaciones**: sin Críticos ni Altos.

## Corregido en `dd0e5ea3`
- **TN-02:** la fila de la cuenta con `UPDLOCK` justo después del padrón (padrón → `Usuarios` → `UsuariosFactor`).
- **TN-03:** `CambiarClaveAsync` comprueba, con el padrón tomado, que el hash siga siendo el verificado (409 si cambió) y pone a cero el contador de CS-5.
- **TN-04:** `/login/factor` vuelve a evaluar el sello de habilitación antes de emitir el token.
- **TN-05:** S-02, S-03 y S-04 con 5 peticiones por minuto y usuario.
- **TN-07:** la publicación pendiente del padrón es de cada transacción; el disco no retrocede.
- **TN-08:** la negativa de `restablecer-factor` manda a `sellos --legitimar` y después a `restablecer-factor`.
- **TN-09:** `FilaEstadoSesion` no imprime el hash ni los sellos.

## Queda abierto
- **TN-01 (Media), para firma del propietario:** la legitimación S-02 de un SUPER cuyo sello difiere en `FactorAlta` o `PasswordHash` se niega y pasa por el restablecimiento (recomendación del auditor; alternativa descartada: solo avisar). No impide unir porque no hay instalaciones de cliente, pero debe cerrarse o aceptarse por escrito antes de la primera.
- **TN-06:** nota de unión del #57 (SUPER sellado con `SinFactorSuper` que ya tenga el factor; solo bases de desarrollo).
- **Candidatas a ADR:** la precisión de ADR-83 de TN-01 y el orden de bloqueos de `GPOS_SYSDATA` (padrón → `Usuarios` con `UPDLOCK` → `UsuariosFactor` → códigos → bitácora).

## Pruebas
Solo pruebas dirigidas (sellos, cambio de RNC y segundo factor), por la inestabilidad del equipo: de 359 a 361 de 364 aprobadas, con 1 a 3 fallos intermitentes y distintos en cada corrida. **La punta anterior `fa00c296` falla igual** (4 de 358), con las mismas dos causas:
- `IOException` sobre `%TEMP%\GPOS_TEST_LICENCIA_<pid>\Licencia\padron` al arrancar las API de prueba en paralelo (`SellosService.EstadoSelladoInicialAsync`, línea 178): todas las fábricas del proceso comparten la carpeta;
- pool de conexiones agotado en las pruebas de concurrencia (PF11, PF_J2_07).

Las fallidas pasan solas. No es una regresión de estas correcciones, pero conviene que la carpeta de licencia de las pruebas sea propia de cada fábrica. **La suite oficial queda para B o A.**

## Reinicio inesperado
El equipo se reinició a las 18:25, con el agente desarrollador a mitad del tramo. Revisión posterior: `git fsck` limpio, archivos sin bytes nulos ni cortes, SQL con 0 páginas sospechosas y `CHECKDB PHYSICAL_ONLY` limpio en las bases GPOS, sin procesos huérfanos. Al tramo solo le faltaba un `using` en la prueba nueva.
