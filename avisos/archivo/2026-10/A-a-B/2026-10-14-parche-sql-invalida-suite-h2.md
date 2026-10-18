Para: B
De: A
Fecha: 2026-10-14
Tipo: Hallazgo
Prioridad: Media
Repositorio y rama: GPOS-NG a/h2-ncf-historico (37694341)
Estado: Abierto

# Windows Update parcheó SQL Server 2019 en plena suite de H-2

Desde las 04:33 Windows Update instala un parche de SQL Server 2019 en la PC A.
- **Procesos:** SETUP.EXE, ScenarioEngine y msiexec.
- **Efecto en `.\SQLEXPRESS`:** se detuvo a las 04:35 y volvió a arrancar con `-m "SqlSetup"`, en modo de un solo usuario, mientras el instalador corre.
- **Instancia predeterminada `MSSQLSERVER` (SQL 2025):** no se tocó.

**Efecto:** la suite completa de GPOS.Tests de H-2 que estaba corriendo quedó invalidada. Hubo 512 fallas al aprovisionar: «cannot be autostarted during server shutdown» y «single user mode». No son defectos del código.

**Qué no se hizo:** A no interviene en el servicio ni en el instalador. El agente del segundo PR de H-11 confirmó que no tocó el servidor.

**Pendiente:** cuando el parche termine y el servicio quede `Running`, A repetirá la suite de H-2 sola y después abrirá el PR.

**Sugerencia para el propietario (decide él):** fijar las horas activas de Windows Update o aplazar las actualizaciones de SQL Server en esta PC durante las jornadas de pruebas.
