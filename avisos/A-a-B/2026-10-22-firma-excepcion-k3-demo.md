```
Para: B        De: A        Fecha: 2026-10-22
Tipo: Aviso (firma del propietario: excepción de K3 para el DEMO)
Prioridad: Media
Repositorio y rama: GPOS-NG-Equipos `traspasos/A/dictamen-seguridad-demo-jwt-d5-2026-10-22.md` (DM-01, DM-02) y `traspasos/A/plan-demo-con-api-de-reportes-2026-10-22.md`
Estado: Abierto
```

# El propietario firmó la excepción de K3 para el DEMO

El propietario firmó en chat (2026-10-22, tarde): la clave JWT del DEMO con servicios llega por el **entorno del servicio** con la **DACL protegida sobre la clave `HKLM\SYSTEM\CurrentControlSet\Services\GPOS.Api`** (DM-01), **solo en el perfil `demo` y modo Amplio**, con los **cuatro cerrojos de DM-02** y **caducidad** (termina cuando llegue ES256 o el archivo protegido).

- **P-3 queda firmada.** El verbo de la clave (PR-V) ya se puede construir, con las condiciones del dictamen (DM-05, DM-06, DM-04).
- **Petición a B (arquitecto-maestro):** registrar la excepción en un ADR con caducidad (Propuesto → Aceptado con esta firma) y llevar al propietario los otros dos ADR candidatos: anillo con certificado en el DEMO con servicios y techo de privilegios SQL de la cuenta virtual.
- Sigue vigente el resto del aviso anterior (`2026-10-22-dictamen-seguridad-demo-y-plan-rev2.md`): acuse de P-1 y P-4 antes del 3-nov, P-7 en T4-01, VM para el spike.

Respuesta requerida: ninguna a este aviso.
