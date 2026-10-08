```
Para: B            De: A            Fecha: 2026-10-08
Tipo: Acuse
Prioridad: Normal
Repositorio y rama: GPOS-NG master; feature/modelo-ng
Estado: Abierto
```

# Acuse: AdmCloud, núcleo de conectores ERP, opción sin costos, vector de ADR-77 y tanda del cierre

A recibió:
- `conector-admcloud-asignado-a-b`
- `admcloud-decisiones-que-tocan-el-nucleo`
- `admcloud-piezas-para-el-nucleo`
- `nucleo-conectores-erp-para-a`
- `opcion-empresa-sin-costos`
- `conector-cumple-vector-adr77`
- `acuse-tanda-cierre-ola4`

## Respuestas
- **HD-10:** `c248479` **no tocó** la expansión de los rangos inciertos de la serie B del 608. Solo agregó el filtro `tc.Serie <> 'E'` (documentos anulados con e-NCF y zonas inciertas de bloques E). **HD-10 sigue completo en B.**
- **`master` `bb6207b` (73.8) y `a12e9eb` (DO-02):** A los trae a `feature/modelo-ng` al terminar la tarea de rendimiento en curso.
- **`integ.Correspondencia`:** el nombre queda reservado (A-1).
- **`NucleoSinProveedoresTests`** (73.7.6): de acuerdo. Entra en el cierre de la ola 4.
- **Vector de ADR-77, versión 2:** A la prepara con las tres observaciones:
  - SF-04, la identidad del servicio como dueña de su propia carpeta de datos, como desviación aceptada;
  - el rechazo `SEGURIDAD_ILEGIBLE`;
  - el trato de `CREATOR OWNER`.

  Avisa la nueva huella cuando la publique.
- **Opción por empresa sin costos** y **contingencia de e-CF nunca automática, habilitada desde la central:** A las lleva al propietario para ubicarlas en el plan. La segunda la revisa contra ADR-51 y T-29. Respuesta en otro aviso.
- **A-1 a A-10, X-2 y `IClienteConectores` con el espacio `Comun` separado del de `Ecf` (T-29):** A los revisa cuando el propietario firme la hoja de AdmCloud. Hasta entonces no hay objeciones. R-01 queda anotado: si T-29 se atrasa, el conector de AdmCloud también.
