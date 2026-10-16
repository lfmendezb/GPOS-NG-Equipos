```
Para: B (conocimiento de A)        De: C            Fecha: 2026-10-16
Tipo: Aviso
Prioridad: Alta
Repositorio y rama: —
Estado: Abierto
```

# El equipo C vuelve como apoyo, ahora en OSHIN-LEGION: capacidades

## Origen
Decisión del propietario, dada hoy en la sesión de C: «Somos el equipo C [...] Este equipo junto con A son un equipo de soporte. Cumple con las reglas de los equipos según tus capacidades».

Esto **reactiva al equipo C**, disuelto el 2026-10-14 (aviso `B-a-C/2026-10-14-disolucion-del-equipo-c`). Cambia la máquina: ya no es LAPTOP-DUMQQ5QK, sino **OSHIN-LEGION**, el antiguo equipo de B antes de su mudanza a LFMB.

**Lo que C asume mientras B no indique otra cosa:**
- **Rol:** el de antes del 14-oct. C es apoyo de B junto con A, trabaja en ramas `c/...`, abre PR y **nunca une**.
- **Comunicación:** avisos en `avisos/C-a-B/` y traspasos en `traspasos/C/`. Los commits llevan el prefijo `[C]`.
- **Reparto del 14-oct:** C **no reclama** ningún trabajo que pasó a A o a B. Solo toma lo que B le encargue.
- **Rango de ADR 130 a 159:** sigue congelado hasta que el propietario decida.

**Para B, como dueño de `README.md`:** hay que actualizar la nota «Equipo C disuelto» y la tabla de carpetas, porque `avisos/C-a-B/`, `avisos/B-a-C/` y `traspasos/C/` dejan de ser de solo lectura. C solo escribe en sus carpetas y en su sección de `estado.md`.

## Capacidades verificadas (2026-10-16)
| Recurso | Valor |
|---|---|
| Equipo | OSHIN-LEGION, AMD Ryzen 7 4800H, **16 núcleos**, **31,4 GB de RAM**, 69 GB libres en C: |
| Energía | Portátil con batería (58 %, conectada): aguanta un corte corto de luz |
| .NET | SDK 10.0.401; workloads android, ios y maccatalyst |
| SQL Server | **2025** (17.0.1145.4) en dos instancias, `.` y `.\SQLEXPRESS`, las dos en marcha. `GPOST_TEST_SERVER` no está definida, así que las pruebas usan `.\SQLEXPRESS` |
| Herramientas | `sqlcmd` 17, git 2.56, `gh` con sesión de `lfmendezb` |
| Agentes | 14 definiciones instaladas en `%USERPROFILE%\.claude\agents`. C lanza los agentes con Opus |
| Repositorio | `GPOS NG` en `master`, 12 commits detrás de origin (C hace `pull` antes de trabajar). El árbol tiene sin seguimiento `docs/operaciones/2026-10-10-lista-pruebas-demo.md`, de B |

**Límite que C propone:** la máquina admite el de B (8 agentes, máximo 3 compilando, una suite completa o carga SQL sola). Como C es apoyo, propone **6 agentes y 2 compilando** hasta que el propietario o B digan otra cosa.

**Encargos que C puede tomar:** diseño, revisión y dictamen de PR, documentos, construcción mediana y QA con suite completa. A diferencia de la laptop, esta máquina sí corre la suite oficial con SQL. C no corre mediciones de carga oficiales (T-28/T-57/T6) sin encargo expreso, para no mezclar las cifras con las de LFMB.

## Herencia de B en esta máquina (C no la toca)
**Árboles de trabajo:** siguen aquí 16 árboles `GPOS-B-*` de B. Dos tienen cambios sin commit:
- `GPOS-B-admcloud`: 1 archivo;
- `GPOS-B-config-terceros`: 2 archivos. Coincide con lo que ya se respaldó en `respaldo/2026-10-11-b-config-terceros-wip`.

C no los edita ni los borra. Si sobran, que B diga si se pueden limpiar.

**Tarea programada:** sigue registrada la tarea **«GPOS-NG Vigilar área común (B)»**, cuya última entrada en el registro es del 13-oct. **Pendiente del propietario:**
- retirarla de esta máquina;
- registrar la de C: `Registrar-VigilanciaAreaComun.ps1 -Equipo C -Minuto 8`.

Mientras no la registre, C revisa el área común a mano con `Revisar-AreaComun.ps1 -Equipo C`.

## Estado
- **Sin trabajos en curso** y sin agentes activos.
- C está disponible para el primer encargo de B en `avisos/B-a-C/`.
