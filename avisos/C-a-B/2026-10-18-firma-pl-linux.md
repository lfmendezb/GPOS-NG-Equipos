```
Para: B (conocimiento de A)        De: C            Fecha: 2026-10-18
Tipo: Firma del propietario (para registrar en master)
Prioridad: Media
Repositorio y rama: GPOS-NG-Equipos traspasos/C (sin rama de código)
Estado: Abierto
```

# Firmada la hoja PL-01 a PL-15 (GPOS NG en Linux), con PL-10 en la opción (b)

El propietario firmó en la sesión de C (2026-10-18, ~12:20), con este texto literal:

> «Firmo todo según recomendación. Haciendo una precisión sobre el punto PL-10 FIPS/Avanzada elijo la opción (b).»

**Resultado:** todos los puntos en la opción (a), salvo **PL-10 (b): Avanzada (FIPS) en Linux desde la primera versión Linux**. Respuesta y consecuencias anotadas al final de la sección 10 de `traspasos/C/propuesta-adr-plataforma-linux-2026-10-18.md`.

## Qué pide a B
1. **Asignar el número y registrar el ADR en `master`**, con las precisiones de la sección 3 y los cambios de PL-10 (b):
   - **Bloque H:** se quita el punto 1 (Linux solo con Básica) y la alternativa descartada correspondiente; rigen las condiciones del punto 2 desde la primera versión.
   - **ADR-64, punto 5:** la alerta diaria deja de ser la regla de Linux.
2. **Relación con PL-04 (a):** con PL-10 (b), la matriz tiene desde el inicio Ubuntu 24.04 para Básica y una distribución FIPS para Avanzada. Leída al pie de la letra, esa distribución es RHEL, con `.rpm` (+0,5 sp). La alternativa es Ubuntu Pro FIPS, si su validación CMVP para 24.04 está vigente (sin verificar). La elección queda para el arquitecto en LS1, y vuelve al propietario si cambia el costo para el cliente.
3. **Costo:** de 5,8 a 6,6 sp en total (*inferido*). El riesgo `tpm2` + FIPS pasa a la ruta crítica de LS1; si falla, Avanzada en Linux falla cerrada.
4. **PL-03:** proponer al propietario qué equipo hace LN (enero de 2027).
5. **PL-02 (desde la firma):**
   - encargar a A H-L1 y H-L2 (≈ 0,05 sp);
   - construir `ILlaveFirmaTokens` dentro de D2 de DB-7, que hace B desde el 2026-11-02;
   - aplicar la regla de costuras a todo código nuevo que toque secretos de máquina, el canal local, carpetas protegidas, la identidad, el servicio o las rutas.
6. **H-L5:** avisar en el repositorio de Backup Tool.
7. `CLAUDE.md`: la línea del «Stack», «Plataformas del servidor: Windows y Linux (ADR-NNN); decidido, no implementado».

## Datos del propietario para las pruebas
- **Impresora:** ya tiene una impresora térmica de pruebas que se configura por red (CUPS por `socket://<ip>:9100` o IPP en LA3 y LA4). No hay que comprarla.
- **Equipo Linux:** una máquina virtual, para validar el funcionamiento, no el rendimiento. Necesita TPM virtual 2.0. La prepara el propietario, y sus mediciones no son oficiales.

## Pregunta del propietario y respuesta de C
El propietario preguntó si conviene empezar ya o esperar al calendario. C respondió: **esperar.** Ahora solo PL-02; LN en enero, como firmó en PL-03. Como única excepción barata, se puede adelantar la prueba de concepto `tpm2` + FIPS (de LS1) a cuando haya capacidad libre después del corte, porque es el riesgo que añadió PL-10 (b).

C sin trabajos en curso.
