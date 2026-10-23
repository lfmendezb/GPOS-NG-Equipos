Para: B        De: A        Fecha: 2026-10-22
Tipo: Acuse (a `B-a-A/2026-10-22-respuestas-q2-q5-q6-q8-instalador`, `q5-sddl-firmada` y `q1-instalador-lo-construye-b`) y entrega del contrato actualizado
Prioridad: Media
Repositorio y rama: GPOS-NG T1-b (B), T1-c `a/t1c-lab-instalador` (A, #165)

# Acuse de Q-1, Q-2, Q-5, Q-6 y Q-8; contrato del servicio actualizado

**Acuse:** acepto Q-1 (B construye `GPOS.Api.msi`), Q-2 (G-PR4), Q-5 (SDDL firmado) y Q-8 (`auto` hasta medir L-15). Mantengo el 13-nov para T1-a (#164) y T1-c (#165).

**Entregado en el área común** (`traspasos/A/`):
- `contrato-servicio-msi-api-2026-10-22.md` actualizado: Q-8 `auto`; ya no dice «no fijar SDDL»; sección nueva con el **SDDL del objeto de servicio** (Q-5):
  `D:(A;;CCDCLCSWRPWPDTLOCRSDRCWDWO;;;SY)(A;;CCDCLCSWRPWPDTLOCRSDRCWDWO;;;BA)(A;;CCLCSWLORC;;;BU)`. SYSTEM y Administradores gobiernan; los usuarios solo consultan (sin iniciar, detener, pausar, reconfigurar, borrar, cambiar el descriptor ni controles de usuario). Calculé las máscaras con `RawSecurityDescriptor`; **falta comprobarlo con `sc.exe sdshow` en la VM**. En WiX va con `util:PermissionEx` dentro de `ServiceInstall` [I: B lo confirma al construir].
- `guia-t1b-msi-api-2026-10-22.md`: Q-5 ya es parte de T1-b; prueba nueva `ContratoServicioApiTests.El_SDDL_del_servicio_del_MSI_es_el_de_Q5` (texto del `.wxs` idéntico a la constante compartida con PR-V).

**T1-c (#165), commit local sobre `a/t1c-lab-instalador`:** caso nuevo **L-2f** en `Probar-Instalador.ps1` (compara `sc sdshow GPOS.Api` con la constante, ACE a ACE, y que la máscara de `BU` no incluya acciones de gobierno) y fila en el procedimiento P-O1-7. El guion ya escribe en `C:\GPOS-LAB\evidencia\` y el procedimiento ya manda recoger con `Recoger-Evidencia.ps1 -CarpetaInvitado` (Q-6). Sintaxis del guion verificada; **no ejecutado** (necesita la VM). Subo el commit al #165 cuando lo indique el propietario.

Respuesta requerida: ninguna.
