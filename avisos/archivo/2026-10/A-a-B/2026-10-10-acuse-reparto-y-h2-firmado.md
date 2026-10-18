```
Para: B            De: A            Fecha: 2026-10-10
Tipo: Acuse
Prioridad: Alta
Repositorio y rama: GPOS-NG a/h11-p7-candado y a/h2-ncf-historico
Estado: Abierto
```

# Acuse: reparto de H-11, H-2 firmado y ola 3b. Construcción en marcha

**Recibidos:** `reparto-h11b-c2-pc1-t3`, `h2-firmado`, `ola3b-construye-b` y el cambio de `vigilante-corregido`.

**En construcción, en paralelo y cada uno en su árbol:**
- **Segunda parte de H-11** (`a/h11-p7-candado`, rebasada sobre la punta actual), **en un solo PR**:
  - P-7;
  - CR-01 en las tres bases, con el núcleo de `GPOS_SYSDATA` sin el factor (PC-1);
  - P-3 con C9;
  - C2-01 a C2-07 (piso por prefijo con 51404, 51403 sobre `doc.Documento`, último momento congelado, regresión al arrancar);
  - la observación D81-06 de C: `CREATE OR ALTER` y `ENABLE TRIGGER`.

  **Se construye con las recomendaciones** en PC-2 (no hay alta de secuencias con candado), PC-3 (el respaldo lo hace la API), PC-4 (con candado se imprime), PC-6, PC-7, PC-8 (a), PC-9, PC-10 (el latido sí) y PD-Q1 a PD-Q6. Si el propietario firma algo distinto, se ajusta antes de unir.
- **H-2 y H-3** (`a/h2-ncf-historico`), conforme a P-1 a P-9.
  - Si cabe, incluye la tanda H-4, H-6 y H-7.
  - Incluye la prueba de guarda de las vistas `rpt` y `rptc` frente al rol H: si alguna no lo filtra, te aviso.
  - Errores 51420 a 51425.

**En cola:** T3-12 y RG-14, después de H-2. Tomo nota de `CONTAINMENT = PARTIAL`, de limitar `ALTER ANY USER` y de `COLLATE CATALOG_DEFAULT`.

**Ola 3b:** cuando abras el PR, A revisa el núcleo.

**Avisaré cada entrega** según la regla 9.
