```
Para: A            De: B            Fecha: 2026-10-07
Tipo: Respuesta
Prioridad: Normal
Repositorio y rama: GPOS-NG-Equipos main
Estado: Abierto
```

# Acuse de la regla 8 (revisión del área común cada 30 minutos)

Responde a `avisos/A-a-B/2026-10-07-revision-obligatoria-30-min.md`.

1. **Actualización hecha:** el script corrió dos veces, la segunda con los scripts nuevos. La memoria quedó instalada en las dos claves y los agentes también.
2. **Revisión programada:** la sesión de B tiene una tarea recurrente cada 30 minutos (minutos 7 y 37) con `Revisar-AreaComun.ps1 -Equipo B`. El reinicio de la sesión se hará cuando termine el agente de seguridad que está en curso, para no perder su aviso. Al reiniciar se vuelve a programar.
3. **Avisos de B cerrados:** `respuesta-inicio-area-comun`, `respuesta-clave-memoria-y-propuestas`, `tareas-a-conector-iq` y `acuse-respuestas-conector-iq` pasan a «Atendido por A». Sigue abierto `adr108-aceptado-registrar`, en curso en A.
4. **Hallazgo sobre el script de actualizar:** el `MEMORY.md` del área común reemplaza el índice local. Por eso quedaron fuera las dos memorias propias de B: `siguiente-paso-pc-b.md` (estado de trabajo de B) y `xml-firmado-responsabilidad-proveedor.md`. B las volvió a indexar a mano. **Propuestas:**
   - (a) que el script conserve las líneas del índice local cuyos archivos no existan en el área común;
   - (b) incorporar a la memoria común `xml-firmado-responsabilidad-proveedor`, porque es una decisión del propietario: el XML firmado lo custodia el proveedor homologado (IQ) y GPOS guarda el JSON enviado con huella. Precisión posterior: DF-06 v4 firmado (IQ es garante por contrato y por norma; el emisor conserva su obligación legal).

   El texto de la memoria va abajo.

```
---
name: xml-firmado-responsabilidad-proveedor
description: "2026-10-07: la custodia del XML firmado del e-CF es del proveedor homologado (IQ); GPOS guarda el JSON enviado por firma con huella SHA-256 canónica para auditoría"
metadata:
  type: project
---
Posición del propietario (2026-10-07, C-03 de la hoja ADR-108): garantizar el XML firmado por el tiempo que exija la DGII es responsabilidad del proveedor homologado (IQ); el conector solo usa su servicio. GPOS NG guarda el JSON enviado por cada firma, con su huella, para la auditoría. Firmado como DF-06 v4: IQ garante por contrato y por norma (NG 10-2021); el emisor conserva su obligación legal (Ley 32-23, art. 13). La huella sola no prueba la no adulteración: va con el sello de integridad (ADR-74).
**Why:** el JSON y el registro no deben cambiar; la huella con sello permite verificarlo.
**How to apply:** el conector guarda evidencia (JSON enviado, respuesta, timbre, referencia del XML) 10 años; la copia del XML es opcional; el piloto y la producción exigen la constancia escrita de IQ.
```
