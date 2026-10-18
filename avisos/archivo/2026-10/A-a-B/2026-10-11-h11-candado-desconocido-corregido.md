Para: B
De: A (continuación por Codex, por encargo del propietario)
Fecha: 2026-10-11
Tipo: Entrega
Prioridad: Alta
Repositorio y rama: GPOS-NG a/h11-p7-candado, 3a3a6920, PR 24
Estado: Abierto

# PR 24: corregida la autorización de escritura con candado desconocido

Hallazgo: CandadoEmpresas convertía la falta de conexión o una lectura SQL fallida en false. El middleware dejaba continuar; una escritura en GPOS_SYSDATA podía ejecutarse sin estado comprobado del candado de empresa. Los disparadores de empresa no protegen otra base y la comprobación de esquema también permite continuar cuando esa base no responde.

Publicado 3a3a6920 en el PR 24: EstadoAsync mantiene el estado desconocido y una escritura HTTP de negocio sin lectura válida recibe 503 ESTADO_CANDADO_NO_DISPONIBLE antes del manejador. Se preservan consultas y excepciones de rutas ya aprobadas; no se agrega ninguna ruta. La vigilancia mantiene su comportamiento previo. Informe: docs/seguridad/2026-10-11-h11-candado-no-disponible.md.

Verificación: compilación con 0 errores y 18 advertencias; CandadoNoDisponibleTests 8 aprobadas, 0 fallidas, 0 omitidas; diff --check correcto. Son pruebas del middleware sin SQL. La configuración generada de VSTest se restauró al terminar.

https://github.com/lfmendezb/GPOS-NG/pull/24

La integración con restauración real y PDS-06 siguen pendientes. Se comprobó además una conexión SqlClient independiente de VSTest con autenticación de Windows: identidad DEVLAB00/lfmen, acceso denegado al abrir memoria compartida. Se repitió después del cambio de GSF comunicado por el propietario: mismo resultado, antes de acceder a las tablas del candado. sqlcmd sí conecta. No se atribuye este bloqueo al usuario GSF ni se propone tocar bases reales.

No se declara aprobado el conjunto de PR 24 ni se une. B mantiene la integración; siguen pendientes H-11 sistema, H-6 aplicación y T3-12/RG-14.