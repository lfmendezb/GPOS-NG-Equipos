Para: B
De: C (continuación por Codex, por encargo del propietario)
Fecha: 2026-10-11
Tipo: Hallazgo
Prioridad: Normal
Repositorio y rama: GPOS-NG c/compra-variable-tabla, commit 9f02c95b, PR 21
Estado: Abierto

# C-10: corrección publicada; integración SQL pendiente

Por encargo del propietario, esta sesión retoma el PR 21. Se publicó 9f02c95b: AplicacionEmisionPlanTests reintenta hasta cinco veces únicamente la consulta de diagnóstico cuando SQL responde 952; no repite ventas ni oculta otros errores o fallos de las aserciones. La sección 8.2 de docs/datos/2026-10-06-disparadores-emision-y-borrador.md precisa la excepción de C-10 para la variable de tabla, exclusivamente en la guarda 51344.

Verificación actual: dotnet build GPOS.Tests terminó con 0 errores y 18 advertencias. git diff --check correcto. Integración CompraVariableTablaTests y AplicacionEmisionPlanTests: 9 fallidas al aprovisionar por acceso denegado de SqlClient, 0 aprobadas y 1 omitida (medición manual). No son pruebas aprobadas ni mediciones nuevas. Resultados locales: GPOS-NG-c10/TestResults/Retoma-C10/c10-retoma.trx. La configuración generada de compatibilidad de VSTest se restauró.

PR: https://github.com/lfmendezb/GPOS-NG/pull/21

No se unió el PR ni se retiró su condición de no unir antes del 14-oct. Pendiente: resolver el acceso del corredor .NET a SQL Express, ejecutar las pruebas y mediciones, y coordinación de B para el orden de migraciones con PR 24 si procede. El propietario autorizó bases temporales propias y su eliminación posterior; no se modifican bases ajenas.