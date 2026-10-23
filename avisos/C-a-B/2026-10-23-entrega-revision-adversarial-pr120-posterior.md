```
Para: B        De: C        Fecha: 2026-10-23
Tipo: Entrega (opcional 10(d)) y hallazgo
Prioridad: Alta (H120P-01 conviene ensayarlo en VM-SRV antes de conectar la llave en D2)
Repositorio y rama: GPOS-NG `feature/modelo-ng` @ `b9efa9fb` (el #120 se unió en `63378fe6`); sin cambios al código
Estado: Abierto
```

# Revisión adversarial posterior del #120 (T2-0, llave de firma de los tokens): Rechazado para conectar la llave en D2

Informe: `traspasos/C/2026-10-23-revision-adversarial-pr120-posterior.md`; pruebas RC-1 a RC-9: `...-pruebas.cs.txt`. Recomendación técnica: pasa a Aprobado con observaciones si un ensayo en VM-SRV descarta H120P-01. Esta PC tiene TPM y la consola no está elevada: las pruebas de TPM del almacén del usuario corrieron; las del almacén de la máquina se omitieron con su motivo (exigen administrador). No ejecuté mutaciones (no se edita `src/`). Lo que dejaste sin correr (`BitacoraSeguridadTests` con `PF46`, `EventIdUnicosTests`, `Rg14Lote2Tests`) dio 24/24 con SQL local.

| ID | Sev. | Hallazgo |
|---|---|---|
| **H120P-01** | **Alta** (verificada en parte) | Con TPM y sin administrador, el almacén de la máquina del Platform Crypto Provider responde «Acceso denegado» (NTE_PERM) a `CngKey.Exists` y a la enumeración (`LlaveFirmaTokens.Windows.cs:70-74`, `:177`, `:303`). Si se confirma, la API (`NT SERVICE\GPOS.Api`, sin administrador) no arrancaría en ningún equipo con TPM; falla cerrada con el 4740, pero la salida previsible en campo es LocalSystem o administrador, contra ADR-44. Dijiste que esa prueba pasaba en tu PC con TPM y sin elevación: puede depender del equipo. Ensayo de una hora en VM-SRV con vTPM antes de D2. Si se confirma: (a) abrir por nombre sin enumerar o (c) llave en el almacén de usuario de la cuenta virtual (cambia BP3 8.2; candidata a ADR). |
| H120P-02 | Media (pruebas) | `La_identidad_que_no_es_exclusiva_del_servicio_se_rechaza` falla 9/9 en mi PC (`LlaveFirmaTokensTests.cs:295`) porque `Existe` consulta el almacén del TPM; no se omite «con su motivo». |
| H120P-03 | Media | La API arranca con una llave activa de software en un equipo con TPM, solo con el 4735 y sin exigir `FIRMA_SIN_TPM_ACEPTADA`; un administrador la saca del TPM sin rastro en la bitácora (RC4). |
| H120P-04 | Media | `HayTpm` solo comprueba que el proveedor se abre; con un TPM sin P-256 (TPM 1.2, inferido) el verbo rechaza `--sin-tpm` y la creación falla: sin salida (R-DB7-04 lo previó). |
| H120P-05 a H120P-09 | Baja o informativa | Fallos sin 4740 (RC6); regla `InheritOnly` cuenta como uso (RC8); no hay retiro de llaves; `verificar` corre como administrador contra `NT SERVICE\GPOS.Api` fijo; estado de lo que quedó sin ensayo de D6. |

**Sin ensayo de D6:** R-D1-09 cerrado en esta PC para el almacén del usuario (no exportable, `kid`, firma ES256: 31 ms de mediana y 35 ms en el p95, 20 firmas); abierto para el almacén de la máquina. **S120-02, riesgo nuevo (inferido):** en el almacén del usuario el TPM aplicó reglas heredadas, incluidos SID de AppContainer; si en la máquina ignora la DACL protegida, `Crear` borraría la llave en todo equipo con TPM: va en el mismo ensayo que H120P-01. P120S-01 sigue abierto (la vía de «llave plantada por un usuario» no sirve porque el sistema operativo lo impide).

**Controles que se sostienen:** un usuario sin administrador no puede plantar una llave en el almacén de la máquina del Software KSP (RC1); `Crear` traduce bien la falta de privilegios y no deja la llave (RC3); la condición 7 vale también para la llave anterior de la rotación (RC5); con la API como LocalSystem la llave de la cuenta del servicio falla cerrada (RC7); las omisiones del commit `0946fa62` funcionan salvo la de H120P-02.

Respuesta requerida: decisión sobre H120P-01 a H120P-07 y ensayo en la VM con vTPM antes de D2.
