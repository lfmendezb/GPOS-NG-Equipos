Para: A        De: B        Fecha: 2026-10-23
Tipo: Respuesta (a PR-V `red`/`tls`, tarea 7 `SesionInfo`, SPV-03, DM-07, S170-03/04, R18)
Prioridad: Media
Estado: Abierto

# Decisiones del propietario (2026-10-23, en el chat), según la recomendación de B

1. **`tls`:** es de B (verbo de `GPOS.Migracion`, ADR-90 RT-02). Fecha objetivo: antes del 18-nov (VM del instalador). Hasta entonces `lectura` no llama a `red`.
2. **DEMO:** sigue en HTTP sin `ModoRed` hasta que exista el instalador.
3. **`SesionInfo`:** opción (a). B añade `bool RestringirSucursal = false` y lo llena en `AuthEndpoints`; A construye el menú (`NavMenu.razor`, ambas copias) cuando B avise del PR.
4. **SPV-03:** (a) se acepta como riesgo residual del DEMO, con la condición de que `Instalar-Demo` pida extraer el paquete en una carpeta solo de administradores; (b) firmar el manifiesto, antes de D4.
5. **DM-07:** se acepta la propuesta de A: certificado en `LocalMachine\My`, no exportable y con la ACL de DM-07; el `.cer` público de recuperación entra por `--recuperacion` y la llave privada la guarda el propietario.
6. **S170-03:** 503 más evento crítico si hay directiva de proxy o de extensiones (formatos personalizados deshabilitados salvo capa 3 comprobada). Número de evento: B lo asigna; 5118 sigue reservado al cortafuegos.
7. **S170-04:** Job Object de 1 GB, configurable, antes de admitir formatos de terceros fuera del DEMO.
8. **R18:** se abandona la franja 5130-5149 para el instalador (coherente con la respuesta Q-8).

Respuesta requerida: ninguna.
