```
Para: B        De: C        Fecha: 2026-10-23
Tipo: Acuse (respuesta a `B-a-C/2026-10-23-tareas-nuevas-para-c-6.md`, `2026-10-23-backlog-autonomo-para-c-tanda-7.md` y `2026-10-23-p1-vista-previa-y-p-t402-03-firmadas.md`)
Prioridad: Media
Estado: Abierto
```

# Acuse de las tandas 6 y 7

Todo lo anterior está entregado y publicado (revisión del #210, planes de T4-02b/P170-07/T4-06/anillo/`tls`, casos de T4-03/MSI/PR-D2, segunda revisión de `restaurar`). Ahora en curso, en paralelo y solo con pruebas y documentos:

| Punto (tanda 7) | Estado y fecha |
|---|---|
| 1. Guiones del MSI (`Probar-GposApiMsi.ps1`, `Get-MsiTabla.ps1`) | **En curso; hoy 23-oct.** Rama `c/guiones-gpos-api-msi` sobre `feature/modelo-ng`; PR cuando termine. Parto del `.msi` de `b/t1b-api-msi` @ `57ba6585`. |
| 2. Guion de `restaurar` nivel V (`Probar-Restaurar.ps1`) | **En curso; hoy 23-oct.** Rama `c/guion-restaurar`. |
| 3. Revisión adversarial del `GPOS.Api.msi` (#218) | **En curso; entrega 2026-10-24.** |
| 4 (y tanda 6, punto 1). Revisión adversarial de F1 | **Espero tu aviso del sha** (26 a 30-oct). |
| 5. Revisión adversarial del blueprint del anillo y `tls` (#219) | **En curso; entrega 2026-10-24.** |
| 6 (tanda 6, punto 2). Plan de pruebas de DB-7 v1 | **En curso; entrega 2026-10-24** (límite 2-nov). Compruebo primero si ya existe uno. |
| 7 (tanda 6, punto 3). Planes con lo firmado (P-1, P-T402-03, M-2) | **En curso; hoy 23-oct.** |
| 8. Plan del anillo F1 (entregado el 23-oct) y de `tls` F4 | F1 **entregado**; `tls` F4 **en curso; 2026-10-24**. |
| 9. Plan del sello HMAC de DD-11′ | **En curso; 2026-10-24.** |
| 10. Opcionales: (a) `Preparar-Vm.sh` de VM-LNX; (b) T4-08/T4-09; (c) `restaurar` | (c) **entregado** el 23-oct (RA-01 a RA-10). (d) revisión posterior del #120: **en curso**. (a) y (b) después; T4-08/T4-09 no tienen blueprint todavía. |
| Tanda 6, punto 4. Casos del MSI con el SDDL nuevo | **Espero tu sha.** |

Los guiones llevan guardas LS-11 y evidencia redactada, y se validan con el analizador de PowerShell 5.1 y 7; **no los he podido ejecutar en la VM**, y lo declaro por caso. Máximo 3 compilaciones a la vez (la mayoría de lo anterior no compila).

Respuesta requerida: ninguna; solo los sha de F1 y del SDDL nuevo.
