```
Para: A        De: B        Fecha: 2026-10-20
Tipo: Aviso (firmas del propietario y reparto de ADR-90)
Prioridad: Media
Repositorio y rama: GPOS-NG master ae5b35f6 (los documentos citados están en el árbol de B, sin unir todavía)
Estado: Abierto
```

# Firmas del 2026-10-20 y reparto de ADR-90

## 1. Hoja de la Ola 5 (tramo 4): firmadas A-1, A-2, A-3 y A-5
Firmadas por el propietario con la opción (a): A-1 (paso temporal: la principal arma el modelo y el render corre en la API de reportes hasta T4-11), A-2 (T4-01 a T4-07 antes del corte; T4-08 a T4-11 en enero; T4-04 no se recorta), A-3 (en la v1 solo se llega a la API de reportes por el reenvío de la principal) y A-5 (el DEMO instala la API de reportes antes de unir D4). Precisión registrada en ADR-109. Siguen **pendientes**: A-4 (antes del 28-oct, por T4-04), A-6, A-7 (antes del 16-nov, por T4-02) y las secciones B y C. T4-01 y T4-05 pueden empezar el jueves 22-oct.

## 2. ADR-90 (red y TLS): firmado, RT-01 a RT-10 y PT-01 a PT-10
Firmado el 2026-10-20 con la revisión de seguridad hecha (`docs/seguridad/2026-10-20-revision-adr090-red-tls.md`) y la hoja de precisiones (`docs/decisiones/2026-10-20-hoja-firma-precisiones-adr090.md`). Incluye `MODO_RED` obligatorio sin valor por omisión, tres clases de subred (PT-05), certificado de servidor de 90 días (PT-10) y que WireGuard no se excluye de Avanzada por ADR-64 (PT-09). PA-5 (plataformas de MAUI) sigue abierta. Todo sigue «decidido, no implementado».

### Reparto propuesto (A confirma o corrige en `A-a-B/`)
- **A:** API y Web (escucha por modo, selector de certificado, URL de la Web por nombre del sitio con conexión a loopback, filtro por IP de la conexión y credencial del nodo solo para `/api/sync/*`), verbo `tls`, agente en modo estación y MAUI en Windows. Contratos primero (arquitecto-software de A).
- **B:** paquete único, parámetros, registro y ACL, reglas de cortafuegos por clase, tarea de renovación y guía de R-VPN-3.
- **Orden para A:** después de DV-07 y del instalador. Pueden hacerse en paralelo, por ser pequeñas: RT-01, la escucha por modo de RT-05 y las reglas de RT-06 (con PT-06).
- **Ojo:** el filtro por IP y la credencial del nodo (PT-05) tocan `Program.cs` de la API, zona de DB-7; avisar a B antes de tocarlo. N-1 sigue siendo de B.

## 3. Emisor
En la PC de B la cuenta de `gh` ya tiene permiso de administrador sobre `GSF.EmisorLicencias`; B revisará el diff directamente.
