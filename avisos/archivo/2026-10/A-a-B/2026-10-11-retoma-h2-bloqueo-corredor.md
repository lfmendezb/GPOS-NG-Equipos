Para: B
De: A (continuación por Codex, por encargo del propietario)
Fecha: 2026-10-11
Tipo: Hallazgo
Prioridad: Alta
Repositorio y rama: GPOS-NG a/h2-ncf-historico (37694341)
Estado: Abierto

# Retoma autorizada: validación de H-2 bloqueada por el entorno

El propietario encargó retomar los pendientes de A y los PR de C en esta sesión y autorizó crear y eliminar bases temporales de pruebas en SQL Express. Se conservan los roles: A y C no unen; B coordina; las firmas siguen en las hojas de cada proyecto.

H-2, H-3, H-4, H-7 y la parte de datos de H-6 siguen subidos en 37694341, sin cambios de código en esta comprobación. La compilación de GPOS.Tests termina; la suite completa no pudo validarse por restricciones del corredor. VSTest falla al vigilar su proceso padre (Win32 5). Una opción de compatibilidad soportada, aplicada solo al runtimeconfig generado y restaurada después, permitió ejecutar el subconjunto NcfHistoricoTests: 16 fallidas, 0 aprobadas, todas bloqueadas al aprovisionar por acceso denegado de SqlClient a SQL Express. No se interpreta como regresión ni aprobación del código. Los resultados quedan en el árbol local GPOS-NG-h2, TestResults/Retoma-H2/h2-historico-compatible.trx.

SQL Express está activo y sqlcmd acepta una consulta de lectura; el transporte TCP no está disponible. No se modificaron servicios, protocolos ni permisos del servidor. No se elimina ninguna base ajena.

Pendiente: resolver el acceso del proceso .NET a la instancia, repetir la suite completa, ejecutar EnsayoImplantacion con QA y abrir el PR de H-2. Continúan pendientes la revisión de seguridad/PDS-06 del PR 24, el segundo PR de H-11, H-6 de aplicación y T3-12/RG-14. Este aviso registra el bloqueo de validación, no cancela el encargo.

La herramienta Monitor de la sesión descrita en la regla 8 no está disponible en Codex; no se creó un reloj alternativo. Se consultaron los archivos locales de novedades al retomar.