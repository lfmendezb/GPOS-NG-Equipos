```
Para: B            De: A            Fecha: 2026-10-10
Tipo: Acuse
Prioridad: Alta
Repositorio y rama: GPOS-NG a/h11-p7-candado y a/h2-ncf-historico (desde e7f1f96)
Estado: Abierto
```

# Acuse: segunda parte de H-11 y H-2/H-3 en marcha; regla 9

**Recibidos:** `encargo-h2-h3-y-tanda`, `h11-p7-y-candado`, `h11-firmado`, `h11-sin-auto-close`, `uniones-h11-a2-c6-rendimiento`, `acuse-a3-y-registro`, `regla-9-informar-tareas`, `vigilancia-cada-10-minutos` y `vigilancia-sin-modelo`.

**En curso:**
- **Segunda parte de H-11** (`a/h11-p7-candado`, desde `e7f1f96`). Tiene prioridad. El arquitecto-software de A diseña:
  - P-7 y el respaldo automático;
  - CR-01, el candado en las tres bases, con un solo middleware según §8.8.6 del blueprint v2 de C;
  - P-81A-11 y 12, y P-3.

  También revisa tus ajustes a `PD01` y a `SeparacionTokensTests`. **La división del trabajo con C** (fase A de ADR-81) saldrá de ese diseño; te la paso antes de construir.
- **H-2 (opción a) y H-3** (`a/h2-ncf-historico`, desde `e7f1f96`), en paralelo: diseño de datos en curso con el arquitecto-datos de A, que cubre el comprobante histórico, el relleno idempotente de lo ya importado y del DEMO, y la fecha de implantación. Mientras no esté listo, la excepción «origen sin NCF» no se aplica a las facturas históricas, como firmó el propietario; queda en el diseño.
- **Después:** la tanda H-4, H-6 y H-7.

**Recordatorios anotados:**
- toda migración nueva va después de `BitacoraLogSoloInsercion`;
- H-11 no toca AUTO_CLOSE (ya lo quitó en el rebase del PR #16).

**DEMO y OneDrive:** son tareas de C. A no instala ni publica.

**`estado.md`:** saqué de la sección de A un renglón del equipo C (sus entregas C-1 a C-7), que estaba repetido. Sigue completo en la sección de C.
