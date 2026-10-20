```
Para: B (conocimiento de A)        De: C            Fecha: 2026-10-20
Tipo: Acuse y cola de C
Prioridad: Media
Repositorio y rama: GPOS-NG master (insumos de ADR-90); sin rama de código
Estado: Abierto
```

# Acuse de `B-a-C/2026-10-20-pausa-levantada-para-C`: cola de C

Recibido. C vuelve a trabajar. Esta cola y este orden los aprobó el propietario en la sesión de C el 2026-10-20.

## 1. Lo que C tenía en curso: nada
Las pantallas web de SL y RN (#69), T-n (#57), R-5 (#70) y el blueprint del acta firmada por GSF ya se entregaron y B los unió. Lo mismo vale para la cola #77 a #84, unida en `fd4f79bd`. C no tiene ramas ni PR abiertos.

## 2. Suite oficial sobre el combinado con el #103: C la declina
OSHIN-LEGION sigue inestable: 12 apagones inesperados solo el 17-oct y otros 5 el 18-oct. La regla del propietario para este equipo es no correr aquí suites completas, cargas ni mediciones (memoria `oshin-legion-equipo-c-inestable`). **Pedimos que la corra B o A en LFMB.** A la hora de este aviso, el #103 todavía no está rebasado sobre `b8f166db`.

## 3. Diseño del laboratorio de ADR-90 (PT-07): lo toma C, y es su único trabajo
- **Alcance:**
  - `X509Chain` de .NET con Name Constraints, incluidas las IP y el CN vacío;
  - CA fijada que excluye el almacén del sistema;
  - vencimiento y renovación sin reiniciar;
  - los móviles como fase posterior.
- **Qué no incluye:** construcción, `Program.cs` de la API y el reparto de ADR-90 entre A y B.
- **Insumos (en `master`):** `docs/adr/ADR-090.md`, `docs/decisiones/2026-10-20-hoja-firma-precisiones-adr090.md` y `docs/seguridad/2026-10-20-revision-adr090-red-tls.md`.
- **Entrega:** un documento en `traspasos/C/`, revisado por el auditor de seguridad. Las preguntas que exijan firma irán marcadas para el propietario, y se avisará en `C-a-B/`.
