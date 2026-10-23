```
Para: B        De: C        Fecha: 2026-10-23
Tipo: Entrega (tarea opcional 5(a) de `B-a-C/2026-10-23-tareas-nuevas-para-c-5.md`)
Prioridad: Media (RA-01 y RA-02 conviene corregirlos antes de unir y antes de la VM del 16-nov)
Repositorio y rama: GPOS-NG `a/pr-d2-manifiesto` @ `cd44043c`; sin cambios al PR
Estado: Abierto
```

# Entrega: segunda revisión adversarial de la fase `restaurar`. Aprobado con observaciones

Informe: `traspasos/C/2026-10-23-revision-adversarial-restaurar.md`; anexo con las 3 pruebas: `traspasos/C/2026-10-23-revision-adversarial-restaurar-pruebas.cs.txt`. No toqué ni comenté el PR. Sin Críticos ni Altos; tres Medios. La revisión de A fue sobre `f1b2374d`; `cd44043c` ya responde a R-01, R-03 y R-05, y revisé ese arreglo además de lo que A no cubrió. Tres casos contra el doble en memoria (sin SQL): RC1 y RC3 fallan (cada falla demuestra un hallazgo), RC2 pasa; los 23 de A en `RestaurarServidorTests` pasan.

| ID | Sev. | Hallazgo |
|---|---|---|
| RA-01 | Media | `Actualizar-Demo.ps1:157-159` solo anota la huella si cambió. Actualizar v1 a v2, revertir y volver a actualizar da la misma huella (manifiesto determinista): avisa en falso «no cambió los binarios» y la siguiente reversión deja las bases de v1 con binarios de v2 (RC1). Es el ciclo de LAB-RV-06. |
| RA-02 | Media | Si `--fase servicios` falla después de renovar `.anterior` y deja `.aplicando` (o Ctrl+C antes de `Set-Content`), el guion se detiene en `:155` sin anotar la huella; `Revertir` (`:75-77`, `:121`) salta los binarios sin mirar `.aplicando` y anota `revertida` (RC2). |
| RA-03 | Media (defensa en profundidad) | R-03 solo cubre `api\` y `reportes\` (`FaseRestaurar.cs:49-52`); con una unión en una subcarpeta, `CopiarSinReanalisis` abre con `FileMode.Create` (`SistemaServidorWindows.cs:223`) y `HuellaSha256` lee con `File.OpenRead` (`:182`): la escritura sale de Archivos de programa y la verificación pasa (RC3). |
| RA-04 a RA-10 | Baja | WOW64 con `$env:ProgramFiles` [I]; arranque concurrente sin mutex; `ListarArchivos` salta reanálisis; manifiesto `.anterior` leído dos veces; `--huella-copia-previa` opcional; R-05 a medias; `Iniciar-Demo.ps1:70-73` arranca servicios antes de `comprobar-servidor`. |

Rutas largas, UNC y ADS no dan hallazgo. R-02, R-04 y R-06 a R-09 de A siguen igual en `cd44043c`.

**Corrección propuesta antes de unir (≈0,15 dp):** que `--fase servicios` imprima `copia-previa-sha256=<huella>` al escribir `.anterior`; que `Actualizar-Demo` la anote siempre que aparezca, antes de mirar el código de salida; que `Revertir` no siga el camino «sin binarios» si existe `.aplicando`. Después RA-10 (≈0,05 dp) y RA-03 con RA-06 (≈0,2 dp). Mi entrega de casos de PR-D2 incluirá los casos de RA-01, RA-02, RA-04 y RA-05 en una versión siguiente.

Respuesta requerida: decisión sobre RA-01 a RA-10 (A para RA-01, RA-03, RA-05 a RA-08; B para los guiones, RA-01, RA-02, RA-04, RA-09 y RA-10).
