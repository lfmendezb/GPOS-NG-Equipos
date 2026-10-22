```
Para: B        De: A        Fecha: 2026-10-22
Tipo: Entrega (dictamen de seguridad del DEMO con servicios; plan del DEMO rev. 2) y peticiones
Prioridad: Alta
Repositorio y rama: GPOS-NG-Equipos `traspasos/A/dictamen-seguridad-demo-jwt-d5-2026-10-22.md` y `traspasos/A/plan-demo-con-api-de-reportes-2026-10-22.md`
Estado: Abierto
```

# Dictamen de seguridad del DEMO con servicios y plan rev. 2

Complementa `A-a-B/2026-10-22-decisiones-del-propietario-demo-con-api-de-reportes.md`. Solo lectura (sobre `origin/feature/modelo-ng` `b4378650`, #152 `cf6ccf98` y `origin/master`); no se compiló ni ejecutó nada.

**Veredicto del auditor de A:** la opción (a) de P-3 (clave JWT en el entorno del servicio con DACL restringida) es **aceptable solo en el DEMO y con condiciones**. El plan en su redacción anterior salía **Rechazado** por tres Altos (DM-01 a DM-03), todos corregibles en el texto sin código; **la rev. 2 del plan ya los incorpora** y queda Aprobado con observaciones. Es una recomendación técnica; la firma es del propietario.

- **DM-01:** `Environment` es un valor de la clave `HKLM\...\Services\GPOS.Api`, no una subclave: la DACL protegida (`O:SYG:SYD:P(A;CI;KA;;;SY)(A;CI;KA;;;BA)`) va sobre la clave entera; orden: crear servicio → DACL → comprobar → escribir el valor; `comprobar-servidor` la revisa.
- **DM-02:** cuatro cerrojos para que la excepción de K3 sea solo del DEMO (el verbo la escribe solo con `--perfil demo` y Amplio; la API en Estricto con `Jwt__Clave` en el entorno no arranca; `Publicar -Destino Cliente` la rechaza; K3 da FALLA fuera del perfil demo) y un **ADR con caducidad** (hasta ES256 o archivo protegido).
- **DM-03:** privilegios SQL de la cuenta virtual en escalera (rol `gpos_api` → `db_owner` por base → `dbcreator` solo si se justifica; **nunca** roles de servidor) y `TRUSTWORTHY` OFF.
- Otros: clave de 48 bytes CSPRNG por instalación, rotación y borrado al desinstalar (DM-05, DM-06); la principal borra `Jwt__Clave` de su entorno antes de lanzar Chromium (DM-04, Media); anillo con certificado (H-17 v2) también en el DEMO con servicios (DM-07, ~0,5 dp); binarios en `Program Files` con verificación en el destino (DM-08); SDDL de los servicios (DM-09); perfil de Chromium confirmado en `%ProgramData%\GPOS NG\Reportes\render` con su SDDL, subcarpeta aleatoria por arranque y borrado (DM-11, **P-7 para T4-01**); casos de ensayo **DE-10 a DE-16**; spike solo en `VM-SRV` desde el punto de control `base`, sin dar roles de servidor «para ver si arranca».

**Esfuerzo del plan rev. 2: 7,25 a 9,0 dp [I, ±40 %]** (antes 6,5 a 8,0). Fechas: PR-D1 del 3 al 6-nov; un PR pequeño de la API (cerrojo 2 y DM-04) entre el 6 y el 13-nov; spike antes del 13-nov; PR-V hasta el 23-nov; PR-D2 con ensayos hasta el 27-nov. La holgura hasta D4 (4-dic) pasa de «justo» a **«muy justo»**.

## Qué pide A a B
1. **Registrar P-1 y P-4 y el esfuerzo nuevo** (7,25 a 9,0 dp) en la hoja de firma del tramo 4 (A-5) y en la planificación de capacidad: el DEMO ya no cabe en 2 a 3 dp. Antes del **3-nov**.
2. **P-7 y DM-11 en T4-01 (#152) o como condición de T4-02/T4-03:** perfil de Chromium en `%ProgramData%\GPOS NG\Reportes\render` (SDDL de DM-11), subcarpeta aleatoria de 128 bits por arranque, borrada al cerrar y purgada al iniciar, `TMP`/`TEMP` del servicio a `\temp`, nunca `--no-sandbox`.
3. **Arquitecto-maestro: ADR candidatos** para llevar al propietario: (1) excepción K3-DEMO con caducidad; (2) anillo con certificado en el DEMO con servicios; (3) techo de privilegios SQL de la cuenta virtual en Amplio.
4. **Casos DE-10 a DE-16 y VM libre en LFMB** para el spike (P-8): ¿quién ejecuta dentro de la VM? (B/C, con el formato de evidencia de C).
5. Pendientes de B ya anotados: P-2, P-5, P-6.

**La excepción de K3 para el DEMO aún no está firmada por el propietario** (aprobó la opción (a) según la recomendación, sujeta a este dictamen y a su firma con caducidad). No se construye el verbo de la clave hasta esa firma.

Respuesta requerida: acuse de B antes del 2026-11-03.
