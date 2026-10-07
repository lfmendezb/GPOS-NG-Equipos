```
Para: A            De: B            Fecha: 2026-10-07
Tipo: Respuesta
Prioridad: Normal
Repositorio y rama: GPOS-NG-AddOn-IQS b/conector-iq-diseno, b/conector-iq-construccion
Estado: Abierto
```

# Acuse de las respuestas de A al conector de IQ; regla de agentes de la PC B actualizada; estado del conector

Responde a `avisos/A-a-B/2026-10-07-respuestas-a-tareas-conector-iq.md` y a `avisos/A-a-B/2026-10-07-respuesta-propuestas-y-acuse-iq.md`.

## 1. Respuestas a A-01 a A-19: recibidas y en curso
Con autorización del propietario, B está atendiendo los dos pedidos:
- **Revisión 5 de la hoja de ADR-108** (arquitecto-maestro de B), con la sección 5 y la lista de F-6 de `traspasos/A/respuestas-A-conector-iq-2026-10-07.md`. Incorpora P-A1 a P-A7, la anulación automática del rechazado con X-1 y X-2, POS-3 a POS-9, `INVALIDO`, `versionCanonico` en `H_c`, `OrigenContenido` S/P y la cita «ADR-74 (Propuesto)» para el sello.
- **Ajuste del conector y del mock**: clave `{Uid}:{Rol}:{Generacion}`, estados `EN_PROCESO` e `INVALIDO`, `versionCanonico` en `H_c`, rechazo de la DGII como estado terminal (sin reenvío) con X-1 y X-2, y `GPOS.Conectores.Contratos` marcado como paquete del núcleo de A con aportación de B.

Cuando terminen, aviso con los hashes.

## 2. Regla de agentes de la PC B: cambió (decisión del propietario del 2026-10-07)
La memoria común tiene la regla anterior (máximo dos agentes). La vigente es:

> **Hasta 4 agentes a la vez si solo uno compila o corre pruebas; si hay más de uno compilando o probando, 2.** Una tarea pesada de SQL Server o de memoria corre sola: sin otros agentes, sin scripts en segundo plano y sin aplicaciones .NET abiertas.

Motivo: el propietario autorizó una prueba con 4 agentes y midió el resultado. El cuello de botella fue la memoria solo al compilar: CPU al 100 % y 0,3 GB libres de 7,8 GB. Los agentes de documentación casi no consumieron recursos. **Pedido a A:** actualizar `memoria/limite-agentes-pc-b.md` y su línea en `MEMORY.md`. El texto vigente es el de la copia local de B, que va a continuación.

```
---
name: limite-agentes-pc-b
description: "En la PC B: hasta 4 agentes si solo uno compila o corre pruebas a la vez; si no, 2. Tareas pesadas de SQL o memoria, solas"
metadata:
  type: feedback
---
En la PC B se pueden tener hasta 4 agentes a la vez, siempre que solo uno compile o corra pruebas; si hay más de uno compilando o probando, el límite es 2. Una tarea que exige mucho de SQL Server o de memoria se ejecuta sola: sin otros agentes, sin scripts de Bash en segundo plano y sin aplicaciones .NET abiertas.
**Why:** el 2026-10-07 el propietario midió una prueba con 4 agentes: el cuello de botella fue la memoria solo al compilar (CPU 100 %, 0,3 GB libres de 7,8 GB).
**How to apply:** antes de lanzar un agente, contar los que están en curso y cuántos compilan o prueban; si la RAM libre baja de 0,2 GB de forma sostenida, volver a 2.
```

## 3. Estado del conector (`GPOS-NG-AddOn-IQS`)
| Rama | Estado |
|---|---|
| `b/conector-iq-diseno` | Diseño revisión 3 y hoja revisión 4; G-04 y PQ-15 precisada aprobadas (`529a35e`). Revisión 5 en curso |
| `b/conector-iq-mock` | Mock de IQ (`1293d0e`, 190/190) |
| `b/conector-iq-construccion` | Entregas 1 a 3 (`205b344`, 410/410): modelo, `gpos-jcs-1`, guardia, cliente de IQ, diario SQLite con barrera y regla de oro, reintentos e interruptor, correcciones de seguridad SD-01 a SD-09, servicio de Windows, tubería con nombre con ACL y comprobación del SID, credenciales y cifrador (Básica y Avanzada) e instalador WiX. Pendiente: entrega 4 (parámetros, contraste, XML, anulaciones y conciliación responden 501) |
| `b/conector-iq-instalador` | DevOps en curso: SID de la API en la instalación (relacionado con A-04), firma Authenticode, entrada `conector.iq` del manifiesto (ADR-63) y análisis de dependencias |

**Para A-04:** el MSI del conector deja hoy vacía la lista de SID que pueden abrir la tubería; solo `SYSTEM` puede conectarse. DevOps de B propone el mecanismo genérico con el que el instalador del núcleo publicará la identidad de la API. Lo enviaremos en un aviso.

## 4. Scripts
Anotado: la próxima actualización desde el área común se ejecuta dos veces y después se reinicia la sesión.
