```
Para: B        De: A        Fecha: 2026-10-20
Tipo: Consulta (antes de abrir el PR de DV-07)
Prioridad: Media
Repositorio y rama: GPOS-NG árbol `GPOS-NG-dv07`, rama local `a/dv07-formato-licencia` sobre feature/modelo-ng @ 6e50de22 (sin commit ni push)
Estado: Abierto
```

# DV-07: parte de la API construida; A espera tu respuesta antes de abrir el PR

Construido: `sucursales` se ignora; `periodo` opcional e informativo (fuera de `crit`); `vence` del módulo opcional; PA-1 (código repetido, 400 `LICENCIA_FORMATO`); PA-2 (`vence` de CONECTOR_ECF y CONECTOR_ERP ignorado, evento **EventId 4742**, una vez por licencia aceptada); códigos desconocidos se conservan sin habilitar nada. 11 archivos, +348/−29. Pruebas filtradas de Licencia y EventId: 510 correctas, 0 fallidas, 1 omitida (ya lo estaba). La suite oficial completa no se ha corrido.

## Necesito tu decisión (A no abre el PR hasta tenerla)
1. **Forma de `ModuloLicenciaDto` (L-02):** pasa a `(Codigo, Vence?, VigenciaEfectiva, Estado, Perpetuo)` según [LIC] 8.4, sin `Activo` ni `Requiere` (dependen de PA-4, abierta). Ninguna pantalla lo consume hoy. ¿Entra?
2. **PA-15 en `EstadoLicenciaService.Modulo()`:** un módulo sin `vence`, perpetuo o con `vence` igual o posterior al de su empresa toma el estado de la empresa con su gracia. Es más que «si falta rige el de la empresa» y no estaba en mi propuesta; sale de la regla firmada v3.2.4. ¿Entra o lo saco del PR?
3. **Añadido por el agente: CL-02** (v3.2.1): un `vence` de módulo nulo, vacío o imposible se rechaza con 400 `LICENCIA_FORMATO`, también en los conectores. ¿Conforme?
4. **No incluido** (decide si alguno entra en este PR o va aparte): patrón del código de módulo CL-03, `avisoDias`/`graciaDias` por empresa (PA-10), textos por `periodo` (4.5) y aviso al SUPER/soporte GSF por el evento PA-2.

## Pendiente después
Ajuste de `GSF.EmisorLicencias` (quitar `sucursales`, `finPeriodoPagado` opcional, conectores sin `vence`, escribir `periodo`) y mover su submódulo; sin eso el emisor deja de compilar contra el nuevo `FormatoLicencia.cs`. Suite oficial antes de unir.
