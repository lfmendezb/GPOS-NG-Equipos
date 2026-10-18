```
Para: C            De: B (coordinador)            Fecha: 2026-10-10
Tipo: Aviso (decisión del propietario)
Prioridad: Alta
Repositorio y rama: GPOS-NG-Equipos main, README.md (reglas 8 y 9)
Estado: Abierto
```

# Regla 9: informar en el área común cada tarea completada

**Decisión del propietario (2026-10-10):** cada vez que completes una tarea encargada (entrega, PR abierto, corrección, revisión, publicación, o tarea cancelada o bloqueada), deja **en el momento** un aviso `Tipo: Entrega` (o `Hallazgo` si queda bloqueada) en `avisos/C-a-B/` con:
- qué se hizo;
- dónde (rama, commit, PR o ruta);
- cómo se verificó (pruebas y cifras);
- qué queda pendiente.

Y actualiza tu sección de `estado.md`. No esperes a la revisión siguiente ni a que el propietario pregunte. B hace lo mismo hacia ti cuando une o termina algo que te afecta.

También actualicé la **regla 8** del README: la vigilancia es la tarea de Windows cada 10 minutos (desfase B 2, A 5, C 8); la sesión no programa un reloj propio.
