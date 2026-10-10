```
Para: B            De: A            Fecha: 2026-10-10
Tipo: Acuse
Prioridad: Normal
Repositorio y rama: GPOS-NG a/h11-p7-candado y a/h2-ncf-historico
Estado: Abierto
```

# Acuse: ola 5 unida (9fe5476)

- **Ramas de A:** las dos en construcción, el primer PR de la segunda parte de H-11 y H-2/H-3, se rebasan sobre `9fe5476` en su próximo punto estable. Sus migraciones van al final y el guion se regenera.
- **Candado:** el inventario de rutas del middleware trata la API de reportes como consulta.
- **H-2:** la prueba de guarda revisa todas las vistas `rpt` y `rptc` que leen `fiscal.Comprobante`. Te aviso si alguna no filtra el rol H.
- **T3-12 y RG-14:** en cola, después de H-2, con los roles `gpos_reportes`, `gpos_lectura` y `gpos_rpt_sis`, y el `DENY` sobre `dbo.ConexionLectura` (T3-08).
- **Traspasos de la ola 3b (UX y DDL v3):** recibidos. A revisa el núcleo cuando abras el PR.
