```
Para: B (copia a C)            De: A            Fecha: 2026-10-10
Tipo: Entrega (diseño) y preguntas para el propietario (por tu conducto)
Prioridad: Alta
Repositorio y rama: GPOS-NG a/h11-p7-candado
Estado: Abierto
```

# Segunda parte de H-11: blueprint v2 con C2-01 a C2-07; PC-7 a PC-10 para firma

**Archivo:** `traspasos/A/blueprint-h11-p7-candado-2026-10-10.md`. La sección nueva V2 y las marcas [v2] reemplazan lo que diga la v1; el esfuerzo vigente está en V2.7.

**Qué cubre del dictamen de C:**
- **C2-01 (piso por prefijo):**
  - el último NCF probado se declara **por prefijo** y puede pasar del `Hasta`;
  - los bloques C con capacidad entran en el plan: lo usado pasa a X y el resto sigue en C;
  - lo emitido de una ampliación que el respaldo no tiene se registra como zona incierta sin bloque;
  - la tabla `fiscal.PisoNcf` en la base de empresa solo sube: es el máximo entre los cortes confirmados y la marca P-7;
  - el piso se aplica en `GuardarSecuenciaAsync` y en el disparador `TR_SecuenciaNcf_Piso` (**51404**) para alta, ampliación, reapertura y bajada del siguiente;
  - nueva regla C10 y pruebas CA-H11-19 a 22.
- **C2-03:** el último momento conocido se congela en la primera detección de cada fork (`sync.DeteccionRestauracion`).
- **C2-04:** R-10 queda verificado. Al arrancar y cada 5 min se detecta una regresión de `Siguiente − 1` frente al piso o la marca: la base se bloquea y se libera con R3. Más la guía de devops.
- **R-12:** las escrituras leen el candado sin caché (unos 0,2 ms); la vigilancia y los errores 51330 y 51403 invalidan la caché.
- **C2-05, C2-06 y C2-07** están cubiertos. PD11 queda con rasgo de carga; **si cambia el filtro oficial, lo decides tú.**

**Para firma del propietario** (*recomendación entre paréntesis*):
- **PC-7, precisión de la cláusula 9 de ADR-53 y extensión de P-7:** el último NCF se declara por prefijo y hay un **piso de NCF que ni el ADMIN puede saltar** al dar de alta, ampliar o reabrir. *(Sí, en el servicio y en el disparador. Es lo único que cierra C2-01).*
- **PC-8:** los bloques C entran en el desbloqueo. *(a: lo usado pasa a X y el resto sigue en C).*
- **PC-9:** la zona incierta sin bloque queda registrada para el contador. *(Sí).*
- **PC-10, extensión de P-7:** un latido de numeración en `GPOS_SYSDATA` cada 5 min, para detectar cualquier copia de archivos adjuntada y no solo las anteriores a un desbloqueo. *(Sí, +0,1 sp).*

Congelar el último momento conocido, la detección por regresión, la lectura sin caché y C2-05 a C2-07 **no necesitan firma**: son decisiones técnicas dentro de lo ya firmado.

**Cambios en preguntas anteriores:**
- **PC-2:** ahora se recomienda **no permitir el alta de secuencias con el candado**. Con el corte por prefijo ya no hace falta registrar la secuencia antes de desbloquear.
- **PC-5:** si se parte en dos PR, C2-01 va obligatoriamente en el primero. Ese primero serían unas 2,75 sp en unos 3 días, y el segundo, el candado de `GPOS_SYSDATA`, unas 0,55 sp, alrededor de un día después.

**Esfuerzo:** **unas 3,3 sp** (de 2,0 a 4,6, inferido); sin el candado de `GPOS_SYSDATA` en A, unas 2,75. **Fecha:** unos 3,5 a 4 días hábiles, uno más que en la v1.

**Sigue sin responder:**
- **PC-1:** la división del trabajo con C. A no construye nada de `GPOS_SYSDATA` hasta tu respuesta.
- PC-3, PC-4 y PC-6;
- PD-Q1 a PD-Q6 del diseño de datos;
- P-1 a P-9 de H-2.

**Propuesta para no frenar:** si me confirmas **PC-5 = dos PR y PC-7**, A empieza **ya** con el primer PR, que es solo la base de empresa con C2-01, P-7 y P-3 y no depende de PC-1. El candado de `GPOS_SYSDATA` va en el segundo, cuando confirmes PC-1.
