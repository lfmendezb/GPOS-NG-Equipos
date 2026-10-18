```
Para: B (conocimiento de A)        De: C            Fecha: 2026-10-18
Tipo: Entrega (propuesta para firma del propietario) + Hallazgo
Prioridad: Media
Repositorio y rama: GPOS-NG-Equipos traspasos/C (sin rama de código)
Estado: Abierto
```

# Propuesta de ADR: GPOS NG en Linux con las mismas garantías que en Windows (servidor y agente de impresión)

Encargo del propietario en la sesión de C (2026-10-18, tarde): «pásalo al arquitecto maestro para que prepare el ADR, y que contemple el poder desplegar el agente de impresión en Linux». El arquitecto maestro de C preparó la propuesta en estado **Propuesto, sin número** (lo asigna B al registrarlo en `master`; el rango de C está congelado, hay libres en el de A del 89 al 99 y el 129 en el de B):

`traspasos/C/propuesta-adr-plataforma-linux-2026-10-18.md` (688 líneas; hoja de firma **PL-01 a PL-15** al final).

## Qué propone, en corto
- **Alcance (PL-01):** Linux se admite como plataforma del servidor y de la estación de impresión con **paridad de garantías**; lo que no tenga equivalente aprobado se bloquea en Linux, nunca se rebaja. Windows no cambia. Tabla de 17 garantías (C1 a C17) con su equivalente y riesgo residual.
- **Equivalencias:** secretos con credenciales cifradas de systemd y TPM 2.0 vía proveedor `tpm2` de OpenSSL (PL-05); sockets Unix con `SO_PEERCRED` (PL-06); `/var/lib/gpos-ng` con vector propio de ADR-77 (PL-07); SQL Server con login SQL siempre, `gpos_srv_reportes` y login nominal del técnico para `GPOS.Migracion` (PL-08); paquetes `.deb` con nfpm por el manifiesto firmado (PL-09); FIPS solo Básica en Linux por ahora (PL-10); Ubuntu Server 24.04 LTS (PL-04).
- **Agente de impresión (PL-11 a PL-13):** modo estación como servicio de sistema, x64 y arm64, imprimiendo por CUPS el mismo PDF que en Windows; ESC/POS después; sin proyectos nuevos (varios destinos en los existentes); entrega 3, tramo 3b, junto con la cola de comandas de ADR-114.
- **Secuencia (PL-02, PL-03):** desde la firma, todo código nuevo que toque secretos, canal local, carpetas, identidad, servicio o rutas pasa por interfaces neutras (en D2 de DB-7, `ILlaveFirmaTokens`); neutralizar el núcleo en enero de 2027 con punto de control; Linux después; DB-7 y la fase B de ADR-81 antes. Costo estimado total 5,3 sp (3,9 a 6,9).
- **Conectores (PL-14):** una instalación Linux se publica solo con el conector de e-CF de la empresa en versión Linux (e-CF exclusivo desde el 15-nov).

## Hallazgos (para B y A)
1. **H-17 v2 ya está construido.** `CifradorAnillo` (`GPOS.Criptografia`) y `src/GPOS.Core/Infraestructura/Anillo/*` están en `feature/modelo-ng` desde `62051f93` (2026-10-14); en Release el anillo exige el certificado (AN-05) y DPAPI queda solo en Debug y en el DEMO. **`CLAUDE.md` (línea 41 y la sección de seguridad) lo sigue dando por «decidido, no implementado»**: corrección para B, que mantiene `CLAUDE.md`. Lo único atado a Windows en ese punto es el almacén de certificados `LocalMachine\My`.
2. **H-L1 (A):** sin `GPOS:DataProtection:Carpeta` configurada, el anillo guardaría las llaves sin cifrar fuera de Windows. **H-L2 (A):** en Linux no se comprueban los permisos de las carpetas del anillo ni de la licencia. El arquitecto propone corregirlas ya como falla cerrada (unas 0,05 sp), aunque hoy nadie las alcance.
3. **H-L5 (Backup Tool):** fuera de Windows deja sus llaves sin protección; es otro repositorio y hay que avisar allí.
4. Dudas abiertas que la tanda LS1 debe probar antes de comprometer nada: uso de la llave del TPM desde .NET por el proveedor `tpm2` (también en modo FIPS); distribuciones admitidas por SQL Server 2025 para Linux; la barra invertida que `usp_RespaldoCopia` agrega a la ruta de respaldo (H-L4).

## Qué sigue
- **Propietario:** firmar la hoja PL-01 a PL-15 (los puntos marcados [Propietario] son solo suyos: alcance, momento y equipo, distribución, FIPS, agente, conectores).
- **B:** con la firma, asignar número, registrar el ADR en `master` con las precisiones de la sección 3 (ADR-24, 29, 41, 44, 53, 54, 58, 63, 64, 66, 75, 76, 77, 79, 82, 83, 108, 109, 114 y H-17 v2), corregir `CLAUDE.md` y, si lo aprueba, encargar H-L1 y H-L2 a A y `ILlaveFirmaTokens` en D2 de DB-7.

C sin trabajos en curso.
