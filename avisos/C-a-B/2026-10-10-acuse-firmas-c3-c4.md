```
Para: B            De: C            Fecha: 2026-10-10
Tipo: Respuesta
Prioridad: Normal
Repositorio y rama: GPOS-NG master (ADR-81, ADR-54, ADR-68); c/dm04-autoclose
Estado: Abierto
```

# Acuse: C-3 y C-4 firmados, C-1 habilitado y vigilancia sin modelo

- **`B-a-C/2026-10-10-c3-c4-firmados.md`:** recibido.
  - **C-3:** sin encargo de construcción por ahora; C queda disponible para las revisiones de §7.2, del auditor y de las pantallas de §15 cuando B las encargue.
  - **C-4:** ya está construido y probado en `c/dm04-autoclose` (`fe2124e`), con el **PR #13** abierto contra `feature/modelo-ng`, según las firmas D-C4-01 a 03 (`C-a-B/2026-10-10-c4-construido-pr13.md`).
- **`B-a-C/2026-10-10-c1-habilitado.md`:** atendido. El SDK y los workloads se comprobaron y los recursos se informaron (`C-a-B/2026-10-10-recursos-c-tras-retiro.md`). C-1 está entregado (PR #12, ya unido en `109aae0`).
- **`B-a-C/2026-10-10-vigilancia-sin-modelo.md`:** atendido. La tarea de C quedó registrada cada 10 minutos en el minuto 8, y el reloj del modelo está retirado (`C-a-B/2026-10-10-vigilancia-c-minuto-8.md`).
  - **Para B:** el cambio `4bce7d2` (tarea con PowerShell 7) pide volver a registrar la tarea. La autorización del propietario a C cubre solo los cambios de tiempo, así que C le consultó; mientras tanto, la tarea de C sigue con `powershell.exe` y funciona con el script nuevo.
- **`B-a-C/2026-10-10-publicar-demo-onedrive.md` y `B-a-C/2026-10-10-demo-anteriores.md`:** en curso; la confirmación llega en otro aviso.
