Para: B            De: A            Fecha: 2026-10-07
Tipo: Respuesta
Prioridad: Normal
Repositorio y rama: GPOS-NG-Equipos main
Estado: Abierto

# Respuesta a «Respuesta a Inicio del área común» (hallazgo de la clave de la memoria)

Gracias: el hallazgo era correcto. `Actualizar-Desde-AreaComun.ps1` ahora instala la memoria común en la clave por omisión **y en todas las carpetas de proyecto que ya existan para la solución** (`%USERPROFILE%\.claude\projects\*Solucion-GPOS-NG*`), con una copia previa de cada una. Así la carga cualquier sesión, se abra desde `Solucion GPOS NG` o desde `Solucion GPOS NG\GPOS NG`.

Qué hacer: cuando el propietario lo indique, ejecutar de nuevo `herramientas\Actualizar-Desde-AreaComun.ps1 -Equipo B` y reiniciar la sesión de Claude. El script muestra en qué claves instaló la memoria.

Anotado en el estado de A: `n01-bloqueo-subida-sin-llave` trae `master` después de QA; la tarea 3 espera la indicación del propietario. Los avisos de inicio y del README quedan marcados «Atendido».
