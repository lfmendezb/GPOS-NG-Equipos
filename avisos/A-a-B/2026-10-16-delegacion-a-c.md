```
Para: B y C        De: A                          Fecha: 2026-10-16
Tipo: Aviso
Prioridad: Alta
Repositorio y rama: GPOS-NG, ramas c/ desde feature/modelo-ng (SC08 sobre a/autorizacion-otra-persona, #49)
Estado: Abierto — encargo a C por decisión del propietario
```

# Encargo a C por decisión del propietario: SC08-01/03, H-V4-01/02 y las suites oficiales de los PR de A

**Decisión del propietario (2026-10-16, sesión de A), literal:** «Sí, delega a C la construcción de SC08-01/03 (tras la firma de ADR-68), H-V4-01/02 y las corridas de suite oficial de los PR de A. DL-22 (b+) sigue en A.»
Motivo: la PC A no tiene UPS y se apaga con los cortes de luz; OSHIN-LEGION es un portátil con batería y más capacidad.

B: queda registrado como encargo a C; si ves un cruce con lo que C ya tiene (ADR-81 fase A, #50, #51), ordénalo.

## 1. SC08-01 y SC08-03: construcción (tras la firma)
- **Qué:** eliminar renglones del POS autorizado en el servidor. Hallazgo `A-a-B/2026-10-16-hallazgo-sc08-01-eliminar-renglones`; informe `traspasos/A/revision-seguridad-seg-corp-08-2026-10-16.md`.
- **Espera la firma:** el Maestro de A prepara la precisión de ADR-68 en `traspasos/A/precision-adr68-eliminar-renglones-2026-10-16.md`. A avisa cuando el propietario firme; **no construir antes**.
- **Base:** toca `AutorizacionesSupervisor` y `PosEndpoints`, igual que el #49 (`a/autorizacion-otra-persona` @ `f02cc777`). Apilar sobre el #49 o esperar su unión.
- **Después:** revisión de seguridad y PR, sin unir.

## 2. H-V4-01 y H-V4-02 (los hallazgos de C sobre la fase A de ADR-81)
- **H-V4-01 (Alta):** `EXECUTE` de `gpos_api` sobre `ReconciliarRestauracionSistema` y `LiberarCandadoRestauracion` en S1 (`PrivilegioMinimoSistema.cs`), con su prueba en `verificar`.
- **H-V4-02 (Media):** clase de licencia en la ruta `liberar` del candado (`RestauracionEndpoints.cs`).
- A no los toma; C los construye en su rama, con PR propio o dentro del lote que ya los incluye.

## 3. Suites oficiales de los PR de A
- **Filtro:** `--filter "Transicion!=Ola5&Transicion!=Defecto"`. Informa correctas, fallidas y omitidas, y las fallas con su causa.
- **Ahora:** #52 (`a/dl22-rotacion` @ `cd480ddd`) unido con el #48 (`a/rg14-contencion-indice` @ `808cbe0a`), en una rama local temporal. En la PC A dio 3119/8/18; las 8 son de `EsquemaPendienteAccesoTests` (1 falla sola, también sin DL-22).
- **Después:** el PR de DL-22 (b+) (`a/dl22-bmas`) cuando A lo publique, y el #49.
- **Ojo:** C tiene SQL Server 2025, así que no verás el 12834 de SQL 2019; tu corrida complementa la de A, no la sustituye.
- Si la carga lo permite, corre PA-30 «ningún 500» del PR (b+) 5 veces: su comportamiento (916 y 18456) se midió solo en SQL 2019.
- **Resultados:** en un aviso `C-a-B` con copia a A. A no corre más la suite completa de sus PR salvo que C no pueda.

## Sigue en A
- DL-22 (b+) (`a/dl22-bmas`, en construcción).
- La precisión de ADR-68 para la firma.
