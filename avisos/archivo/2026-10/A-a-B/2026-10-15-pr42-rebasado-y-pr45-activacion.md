```
Para: B        De: A                          Fecha: 2026-10-15
Tipo: Entrega
Prioridad: Alta
Repositorio y rama: PR #42 — a/lic-l1b-2 @ 5c9c6a30 (sobre 7898beeb); PR #45 — a/lic-activar @ 33abf1b3 (base a/lic-l1b-2)
Estado: Abierto — #42 listo para tu validación; #45 no se une hasta la reimpresión por POST
```

# PR #42 rebasado sobre `7898beeb`, con los 5 motivos atendidos; PR #45 (activación de `UseLicencia`) abierto

## #42: los 5 motivos del rechazo
Comentario punto por punto: https://github.com/lfmendezb/GPOS-NG/pull/42#issuecomment-6202379386

1. **Interruptor `GPOS:Licencia:Aplicar`:** fuera de `src`. `Program.cs` no llama a `UseLicencia`, y QA-L06 falla si alguien lo condiciona.
2. **Estricto sin `InstalacionId`:** resuelto con #39. Prueba nueva: `En_Estricto_arranca_con_el_InstalacionId_que_genera_GPOS_Migracion_sistema`.
   - **Sin la fila, la API sigue sin arrancar en Estricto.** Lo exige C-08, firmada, en `ExigirInstalacionAsync` (#39).
   - **Confirma la lectura:** si querías que arrancara sin la fila, eso contradice C-08 y necesita una firma.
3. **`/api/super/licencia`:** la Web y MAUI ya usan L-04, L-02 y L-03. Ningún cliente llama a L-09 (410).
4. **DL-02 (a):** la marca «pendiente de firma» se retiró. La regla Produccion/Beta en Amplio cita DL-02 (a).
5. **Caché del RNC:** sin pool y por empresa; se renueva al arrancar, al aceptar, al invalidar y cada 15 min.

## Verificación
| Corrida | Resultado |
|---|---|
| Compilación de la solución | 0 errores |
| Licencia + Arquitectura + usuarios + Rg14Lote2b | 676 correctas; 2 ajenas: `SucursalOrigenTests` (Ola5) y PA28 (contención) |
| Web | 655/655 |
| MAUI | 561/561 |
| **Suite oficial** | **3077 correctas, 18 omitidas y 5 fallas** (26 min 47 s) |
| Activación (#45): Licencia + QA-L06 | 423 correctas |
| Activación (#45): anfitrión | 5/5 |

- **Las 5 fallas de la suite oficial** son las del hallazgo 12834 (aviso `2026-10-15-pr44-dl02-s0-y-hallazgo-12834`), no del #42.
- K1_01 y CP170 pasaron.

## #45: activación
- Una línea en `Program.cs` más la prueba de anfitrión. Ya se puede, porque C-5 y DL-21 están firmadas.
- **No se une todavía:** falta la **reimpresión por POST**, la decisión 1 de la validación del arquitecto. Hoy `documento`, `ticket` y `nota` siguen por GET con la excepción LB-05. A la construye ahora en un PR propio.
- **Orden de unión:** #42 → PR de la reimpresión por POST → #45.

## Pendiente
- Un PR corto que quite las marcas «pendiente de firma» de DL-03, DL-04, DL-16, DL-18 y DL-19 en `EstadoLicenciaService`, que ya están firmadas.
- La suite completa con `UseLicencia` activa: se corre sobre el #45 antes de unirlo.
