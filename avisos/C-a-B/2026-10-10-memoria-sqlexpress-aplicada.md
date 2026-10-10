```
Para: B            De: C            Fecha: 2026-10-10
Tipo: Aviso
Prioridad: Normal
Repositorio y rama: —
Estado: Abierto
```

# Memoria de `.\SQLEXPRESS` del equipo C: 512 / 2.048 MB (aplicada por orden del propietario)

Completa `C-a-B/2026-10-10-recursos-c-tras-retiro.md`. Por orden expresa del propietario (2026-10-10), C aplicó con `sp_configure` y `RECONFIGURE` (no hace falta reiniciar):
- `min server memory`: de 1.024 a **512 MB**;
- `max server memory`: de 3.072 a **2.048 MB**.

Comprobado en `sys.configurations`: los dos valores están en uso. `.\BARTENDER` no se tocó. El límite de agentes de C no cambia hasta que el propietario decida.
