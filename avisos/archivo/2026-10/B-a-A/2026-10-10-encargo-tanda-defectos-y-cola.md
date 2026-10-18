```
Para: A            De: B (coordinador)            Fecha: 2026-10-10
Tipo: Encargo (aprobado por el propietario el 2026-10-10)
Prioridad: Normal (H-11 va primero)
Repositorio y rama: GPOS-NG, ramas a/ desde feature/modelo-ng 42e13b6
Estado: Abierto
```

# Encargo: tanda de defectos cortos y cola después de H-11

**Prioridad:** H-11 (`2026-10-10-encargo-h11-desbloqueo-restauracion`) es lo primero. Si tienes agentes libres mientras H-11 espera revisión, adelanta la tanda A-2. A-3 y A-4 van **después** de entregar H-11. Por los apagones de la PC A: commits y push frecuentes, tareas cortas.

## A-2: tanda de defectos cortos (rama `a/tanda-defectos-1`, un PR)
1. **ADR-50:** los parámetros `desde`/`hasta` de la lista de ventas POS van como `nvarchar` (lo detectó `BusquedaNumeroTests.C7_las_tres_listas…`); tipo y largo de su columna.
2. **`"NumpadEnter"`:** limpiarlo en las ~15 pantallas anteriores al PR #6 (el Enter del numérico llega como «Enter»).
3. **C6-03:** `autocomplete` en `DialogoAutorizacion`.
4. **Estabilizar `EsquemaPendienteAccesoTests`** (falla intermitente bajo carga; en B se vio «BeginExecuteNonQuery requiere una Connection abierta»), con QA. No toques la prueba de `Transicion=Defecto` (`Una_empresa_cuya_base_no_existe…`): es un defecto conocido aparte.

## A-3 (después de H-11): RG-04 y RG-05
«No generar comprobante» exige un privilegio propio del grupo «Especiales» (junto a «Ver costos») y deja su línea en `_LOG`. Sin el privilegio y sin secuencias vigentes, el selector dice «No hay secuencias NCF vigentes; avise al administrador». Regla del propietario: ningún texto sugiere «No generar comprobante» como alternativa. Revisión de seguridad.

## A-4 (después de H-11): RG-30
Todos los títulos del menú con mayúsculas de título, como «Gestión de Secuencias» (Web y MAUI; paridad).

Un PR por tarea contra `feature/modelo-ng`; no unir.
