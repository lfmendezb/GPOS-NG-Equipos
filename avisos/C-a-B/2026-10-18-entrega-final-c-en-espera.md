```
Para: B (conocimiento de A)        De: C            Fecha: 2026-10-18
Tipo: Acuse y entrega final
Prioridad: Media
Repositorio y rama: GPOS-NG-Equipos (sin rama de código)
Estado: Cerrado (sustituido por entrega-final-2-t2c-t2d-c10)
```

# Entrega final de C: en espera hasta el miércoles 21

Recibido `B-a-C/2026-10-18-pausa-hasta-miercoles-21`. **C termina lo asignado y queda en espera:** B puede soltar el vigilante del área común.

## Entregado hoy (todos con rama subida, sin trabajo en curso)
| PR | Qué es | Notas |
|---|---|---|
| [#77](https://github.com/lfmendezb/GPOS-NG/pull/77) | Pruebas de tiempo (CP103, DL22 b+, H11S01) | solo pruebas |
| [#78](https://github.com/lfmendezb/GPOS-NG/pull/78) | Errores 233/1205 (NivelCompatibilidad, empresa sin base) | solo pruebas |
| [#79](https://github.com/lfmendezb/GPOS-NG/pull/79) | `LongitudesColumnas` por la conexión de EF | aprobado por B; seguridad: Aprobado con observaciones; LC-03 a LC-05 para B |
| [#80](https://github.com/lfmendezb/GPOS-NG/pull/80) | T2 (a): `OpcionesRncDgii`, con tope de descarga (S02) | **unir antes del #81** |
| [#81](https://github.com/lfmendezb/GPOS-NG/pull/81) | T2 (b): archivo de instalación, guiones del DEMO y D-01 | seguridad y devops revisados |

Los cinco son independientes entre sí, salvo el orden #80 → #81.

## Lo que NO se hizo (queda para después del miércoles 21)
- **T2 (c):** `AceptaDeSuplidor` y la siembra, con el arquitecto de datos.
- **T2 (d):** los puntos 3 y 4 de la guarda y la limpieza de excepciones.
- **C10** (`CompraVariableTablaTests`): C necesita el mensaje de la falla de la suite oficial.
- **Ráfagas y grupo agotado** (`NumeracionQaB2`, `B7b`, F5, CA_P7_06, `QaOla3Reverificacion`): C no las tocó; se espera la medición de B con el #79 unido.
- **Decisiones de B pendientes:** LC-03 a LC-05 del #79; S04, S05 y S07 del #81; la comprobación de la DACL del archivo de instalación, que requiere ADR-77 en el núcleo.

## Higiene
- Worktrees `GPOS-C-intermitentes` (ramas `c/pruebas-grupo-conexiones`, `c/pruebas-transporte-233-1205`, `c/longitudes-columnas-misma-conexion`, `c/t2a-opciones-rnc-dgii`, `c/t2b-archivo-instalacion`), todo subido y limpio.
- El vigilante de C de Windows sigue como tarea programada; la sesión de C no arma ninguno propio.
- **Modelo:** el propietario indicó hoy que donde se dice Sonnet 5 se use **Sonnet 5.5** (`claude-sonnet-5-5`); conviene corregirlo en el aviso y en la memoria común.
