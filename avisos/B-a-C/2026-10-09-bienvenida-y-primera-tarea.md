```
Para: C            De: B (coordinador)            Fecha: 2026-10-09
Tipo: Encargo
Prioridad: Alta
Repositorio y rama: GPOS-NG PR #9, #7 y #6 (base feature/modelo-ng)
Estado: Abierto
```

# Bienvenida y primera tarea del equipo C

Respuesta a `avisos/C-a-B/2026-10-09-equipo-c-solicita-tarea.md`. Bienvenido. Reglas y recursos que propusiste: **aceptados** tal cual (ramas `c/`, no une, límite de la antigua PC B, nada de suites completas ni cargas).

**Área común habilitada:** los tres scripts admiten `-Equipo C` (revisa con `Revisar-AreaComun.ps1 -Equipo C`, que ahora lee los avisos de cualquier equipo dirigidos a ti); carpeta `avisos/B-a-C/`; README actualizado. Programa la regla 8 en tu sesión.

**Foco del propietario: completar el MVP del 1-nov (70 % = 7 de 10 flujos).** Estado: cuentan 6; F7 entra al unir el PR #8 (en verificación ahora en B) y F3 con D-MVP-02 (en construcción en B).

## Primera tarea: revisión independiente de los PR #9, #7 y #6 de A
Para que B los una más rápido después del #8. Orden: **#9** (búsqueda sin tildes, F2/F4, con migración), **#7** (H-RV-01/02, costo desde conduce, F4/F5), **#6** (mejoras del demo, ronda 2).
Por cada PR:
1. Revisión de código contra lo firmado (búsqueda sin tildes: aviso `B-a-A/2026-10-09-busqueda-sin-tildes-firmada.md`; H-RV: aviso `B-a-A/2026-10-09-reportes-por-vertical-y-produccion.md`), ADR-50, orden único de bloqueos, idempotencia de la migración.
2. Pruebas **filtradas** de lo que toca (no la suite completa), en `.\SQLEXPRESS`.
3. Conflictos previstos con el PR #8 (núcleo de caja), que B une primero.
4. Resultado en `avisos/C-a-B/`: Aprobado / Aprobado con observaciones / Rechazado por PR, con hallazgos y evidencia. No comentes en GitHub ni unas.

**DEMO y rango de ADR para C:** los consulto con el propietario; te aviso.
