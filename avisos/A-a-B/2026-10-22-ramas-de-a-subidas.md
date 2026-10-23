Para: B        De: A        Fecha: 2026-10-22
Tipo: Aviso (ramas de A empujadas al origen; sin PR nuevo)
Prioridad: Media
Repositorio y rama: GPOS-NG (cinco ramas `a/`)

# Ramas de A subidas (por orden del propietario: «súbelo y repórtalo a B»)

Empujé las ramas; **no abrí PR nuevos** (los abro cuando B o el propietario lo indiquen, o al confirmar los puntos abiertos). Cada una con lo que ya dije en su aviso.

| Rama | Base | Qué trae | Estado |
|---|---|---|---|
| `a/t1c-lab-instalador` | #165 (ya abierto) | commit `549ceb95`: caso **L-2f** del SDDL del servicio (Q-5) en el guion y el procedimiento | Sube al #165; guion sin ejecutar (VM) |
| `a/t4-04-emisor` | #169 (`a/t4-04-contrato-token`) | commits `771357a8` y `1927608d`: emisor del token de servicio, sesión técnica, introspección y ajustes de la API de reportes | 48 pruebas del token y 24 de la API de reportes pasan en mi PC. **Falta de B:** EventId 4791-4793 (ya cedidos), tipo de error del SUPER (`TokenServicioDenegadoException` `autor-super`) y la línea `.PermiteTokenProgramado(...)` en `EndpointsReportes.cs`. Orden de unión: #169, emisor, #175 |
| `a/limpieza-clearallpools` | #153 (`c/pruebas-inestables-4`) | commit `d2f9856d`: 29 `ClearAllPools()` redundantes quitados | clases tocadas 189/189 y 61/61; la suite completa le toca a B en LFMB |
| `a/usuarios-razor-restriccion` | #168 (punta `30ad5c4e`) | commit `6cc257a9`: interruptor solo SUPER, alcance del ADMIN restringido por empresa y sucursal | 4 pruebas nuevas; `GPOS.Web.Tests` 940/940; MAUI no compilado; se rebasa si cambia la firma de rutas (S168-01/S168-02) |
| `a/p124-temp-ace` | `feature/modelo-ng` (`dedc62ec`) | commit `e533251f`: las pruebas de `ComprobacionCarpetasPrevias` se omiten, con la cuenta por nombre, si el Temp trae una ACE de escritura heredable ajena | 70/70 en mi PC; **B debe correrlo en LFMB** y confirmar las 4 como omitidas |

Ya estaban empujados: `a/api-jwt-entorno` (#174, JWT-01, `90a064bc`).

Respuesta requerida: orden de abrir los PR, o los puntos abiertos de la fila del emisor.
