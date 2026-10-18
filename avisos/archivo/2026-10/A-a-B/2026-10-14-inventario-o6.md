Para: B (para el propietario)
De: A
Fecha: 2026-10-14
Tipo: Entrega
Prioridad: Media
Repositorio y rama: área común traspasos/A/inventario-o6-equipo-a-2026-10-14.md
Estado: Abierto — decisión del propietario

# Inventario O-6 de la PC A (solo lectura): no cumple E-1; se recomienda no generar `s1` aquí

- **No cumple E-1:** `lfmen` está en `Administradores` (no hay otra cuenta administradora habilitada); UAC en 5 (E-1 pide 2); `lfmen` es `sysadmin` en `.\SQLEXPRESS`, `.` y LocalDB.
- **Sí cumple de SEG-L2-25:** grupos Hyper-V, remotos y de copia vacíos; sin Docker ni WSL.
- **Desarrollo sin `sysadmin`:** viable con `dbcreator` (las bases son de `lfmen`); solo fallarían dos pruebas que crean logins y `crear-lectura-sistema --cuenta`. El login aparte no puede ser `gsf` (`GPOS.Migracion` lo rechaza): se propone uno nuevo (`lm_dba`) con permisos mínimos, candidato a ADR.
- **Otras condiciones que fallan:** E-13 (arranque seguro deshabilitado, `w32time` sin sincronizar), E-5 (AnyDesk como servicio `LocalSystem`), E-10 (BitLocker probablemente inactivo), E-2 (no existe `gsf-firma`). TPM 2.0 discreto Infineon, no vulnerable.
- **Costo de cumplir E-1 aquí:** ≈0,75 dp, sin dinero; luego 5-15 min/semana de elevaciones. Lista de cambios W-1 a W-6 y S-1 a S-8 en el informe (no ejecutados).
- **Recomendación:** endurecer la PC A si se quiere, pero **no usarla como equipo emisor** (E-5, E-10, E-13; equipo de soporte, sin UPS). Para AI-09, **DL-10 (b) YubiKeys**; si `s1` va en un TPM, repetir O-6 en el equipo que sea de verdad el principal (no está confirmado que lo sea la PC A).
- **Pregunta al propietario:** ¿para qué es la cuenta local estándar `BigLocker`?
