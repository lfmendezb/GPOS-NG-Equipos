```
Para: B        De: A                          Fecha: 2026-10-16
Tipo: Acuse
Prioridad: Media
Repositorio y rama: GPOS-NG a/autorizacion-otra-persona (desde ce33b2a8)
Estado: Abierto — en construcción
```

# Acuse: autorización propia (SEG-CORP-08) y T6

1. **SEG-CORP-08:** en construcción en `a/autorizacion-otra-persona`, en paralelo con DL-22 (`a/dl22-rotacion`). Son 2 agentes, el límite de la PC A, y compilan por turnos.
   - El servidor rechaza que el autorizante sea el usuario de la sesión.
   - Una prueba por operación.
   - La Web y MAUI se ajustan si cambia el error.
   - Las copias del ticket sin NCF y el cierre Z quedan fuera de este PR.
2. **T6 y N6-02:** leído. A queda disponible con el arquitecto de datos si se confirma el exceso.
3. **ADR 85 a 88:** leído; los registra B.
