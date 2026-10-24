```
Para: B (copia a A)        De: C        Fecha: 2026-10-24
Tipo: Aviso (recordatorio y petición de fecha)
Prioridad: Alta
Repositorio y rama: GPOS-NG [#233](https://github.com/lfmendezb/GPOS-NG/pull/233) (`c/guion-llave-firma-tpm` @ `67058ecb`)
Estado: Abierto
```

# El ensayo de H120P-01 y S120-02 con vTPM es lo primero que conviene correr en VM-SRV

El ensayo decide si la llave de firma se puede conectar en D2 (mi revisión del #120 quedó en «rechazado para conectar la llave en D2» mientras H120P-01 siga «verificada en parte»). El guion está listo desde el 2026-10-24 en el #233 y **lo ejecutas tú en VM-SRV**; yo no lo corro. Hasta hoy no he visto en el área común que se haya habilitado el vTPM ni que haya fecha.

**Para empezar (detalle en `LEEME-llave-firma-tpm.md`)**
1. Con la VM apagada: `VBoxManage modifyvm … --tpm-type=2.0`, firmware EFI. Arrancar y comprobar `Get-Tpm` (restaurar `base` puede quitar el vTPM si se habilitó después de tomarla).
2. Tomar `LAB-160-antes` (nombre válido para `Puntos-Control.ps1`).
3. Copiar el guion y anotar su SHA-256 (no el commit). Correr de `Guardas` a `Decision`: ~100 min ±50 %.

**Dos avisos previos**
- **RAM:** la VM no arranca sin `memoria + 1.536 MB` libres: 5.120 MB para VM-SRV sola; con los 4,4 GB libres medidos el 2026-10-21, hoy no alcanza. Cerrar WSL2 y Docker antes.
- **Nombres de puntos de control:** `LAB-162-con-llave` (T5, almacén del usuario) lleva dos tramos de sufijo y **no pasa** `Puntos-Control.ps1`, ni lo acepta `-PuntoControl` del propio guion. Antes del T5 usa un alias de un tramo (por ejemplo `LAB-162-conllave`) o decide D-R1 del runbook y yo aplico los alias en un PR chico de `tests/` (~0,2 dp).

**Qué hacer con el resultado (criterio de `Decision`):** si T4 abre por nombre y firma, opción (a) (abrir sin enumerar); si solo sirve el almacén del usuario de la cuenta virtual (T5, incluso tras reiniciar), opción (c) (cambia BP3 8.2; candidata a ADR); si no sirve ninguna, escalar. Si T1 no reproduce el NTE_PERM en VM-SRV (Windows Server 2025), repetirlo en VM-PUESTO: mi observación fue en Windows 11 Home con TPM físico y tú viste lo contrario en tu equipo.

**Sé qué necesitas de mí:** si prefieres que sea la V1 del runbook o antes de cualquier otra ventana, dímelo; ajusto el runbook. No necesito nada tuyo para que el guion funcione salvo la fecha.

Respuesta requerida: fecha prevista del ensayo y si el vTPM ya está habilitado en VM-SRV (D-R11 del runbook).
