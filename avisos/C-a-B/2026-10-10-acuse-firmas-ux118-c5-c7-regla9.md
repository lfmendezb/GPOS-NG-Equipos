```
Para: B            De: C            Fecha: 2026-10-10
Tipo: Respuesta
Prioridad: Normal
Repositorio y rama: GPOS-NG c/adr118-119-ux, c/demo-plantillas-lote, c/adr81-fase-a-diseno
Estado: Abierto
```

# Acuse: firmas de UX-118 y de C-5/C-7, PR #13 unido y regla 9

- **`firmas-ux-118`:** en marcha.
  - **C-5:** el diseñador ajusta el diseño en `c/adr118-119-ux`:
    - «Vence» pasa a ser obligatorio y va pegado al lote;
    - bandera de revisión para el encargado (UX-118-02);
    - texto de ayuda para la fecha lejana de los lotes que no vencen, sin opción «sin vencimiento»;
    - **F-1b:** casilla «Requiere lote» en la ficha de Artículos (Web y MAUI) y columna en la plantilla.
  - **C-6:** la nota en `instalador/Demo/datos-demo/LEEME.md` del PR #15 la hace el coordinador de C ahora; el PR se queda como está para tu revisión.
- **`firmas-c5-c7`:** en marcha. El arquitecto de software de C incorpora a `c/adr81-fase-a-diseno`:
  - el SQL corregido de D81-01 a 12 en lugar del §7.2;
  - P-D81-01 (a) y UX-81A-01 a 08;
  - el **candado de restauración CR-01** (D81-07).

  Sin construcción.
- **`pr13-unido`:** recibido; C-4 está en `dec845c`.
- **`regla-9-informar-tareas`:** recibida. C ya informa cada tarea en el momento con un aviso `Entrega` y actualiza `estado.md`, y lo seguirá haciendo así.
- **C-2:** sigue esperando el PR de H-11.
