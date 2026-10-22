```
Para: B        De: A        Fecha: 2026-10-22
Tipo: Aviso (decisiones del propietario sobre el plan del DEMO con la API de reportes) y peticiones
Prioridad: Alta (plazos: 2026-11-03 y 2026-11-06)
Repositorio y rama: GPOS-NG-Equipos `traspasos/A/plan-demo-con-api-de-reportes-2026-10-22.md`
Estado: Abierto
```

# Decisiones del propietario (chat, 2026-10-22) sobre el plan del DEMO

Complementa `A-a-B/2026-10-22-relectura4-p140-03-y-plan-demo-con-api-de-reportes.md`. El propietario aprobó:

| Punto del plan | Decisión | Qué se pide a B |
|---|---|---|
| **P-1 (D-1):** el DEMO pasa a dos servicios con elevación (`NT SERVICE\GPOS.Api` y `NT SERVICE\GPOS.Reportes`) y su esfuerzo es de **6,5 a 8 dp** | **Aprobado** | Registrarlo (la hoja de firma del tramo 4 decía 2 a 3 dp para A-5) y reflejarlo en la capacidad: T4-06 y el token ocupan los cupos de A desde el 3-nov. Antes del **3-nov** |
| **P-4:** T4-06 conserva el nombre `CompilacionDepuracion` en `ReenvioReportes.cs` (marcador de la guarda de `Publicar`), **no se une antes de PR-D1** y no se publica ningún DEMO de `feature/modelo-ng` entre T4-06 y PR-D2 | **Aprobado** | Que el PR de T4-06 conserve el nombre (o añada una constante con ese nombre) y respete el orden. Antes del **6-nov** |
| **P-3 (D-3):** la clave JWT llega al servicio por el entorno del servicio con DACL restringida a SYSTEM y administradores, excepción del K3 **solo para el DEMO** (modo Amplio, no se entrega a clientes) | **Aprobado según la recomendación**, sujeto al dictamen del auditor de seguridad de A (en curso: `traspasos/A/dictamen-seguridad-demo-jwt-d5-2026-10-22.md`, condiciones DACL, generación por instalación y límite al DEMO) | Nada aún; A avisa con el dictamen |
| **P-7 (T4-01):** el perfil de Chromium va a **`%ProgramData%\GPOS NG\Reportes\render`**, no a TEMP | **Aprobado** | **Pedido a B:** cambiar el perfil de Chromium en T4-01 (#152; hoy va a TEMP) o dejarlo como condición de T4-02/T4-03, con la ACL del servicio de reportes; antes de unir T4-01 |

Pendientes que siguen siendo de B: P-2, P-5 y P-6 (spike de D-2/D-4 y modo de red con PR-4), P-8 (VM libre en LFMB y quién ejecuta dentro) y el resto de las preguntas de la sección 7 del plan.

Fechas de A sin cambio: PR-D1 del 3 al 6-nov (unido antes del 11-nov, un día antes que T4-06), spike antes del 13-nov, PR-D2 con ensayos del 16 al 27-nov, unido antes de D4.

Respuesta requerida: acuse de B con el registro de P-1 y P-4 antes del 2026-11-03, y su respuesta sobre P-7.
