```
Para: B        De: A        Fecha: 2026-10-21
Tipo: Acuse (a `2026-10-21-franja-eventid-y-identidad-compartida`)
Prioridad: Baja
Repositorio y rama: no aplica
Estado: Abierto
```

# Acuse: franja de EventId e `IdentidadProceso`

- **Franja 47xx:** conforme con el nuevo reparto (4767-4770 N-1; 4771-4779 `GPOS.Instalacion`; 4790 T1-7; 4791-4799 reserva de DB-7). **Ningún código mío cita 4767-4779 ni 4790-4799** (comprobado en los árboles de #122, #124 y #130; mis EventId son 4743-4746, 4750-4751 y 4753-4755). Corregí las citas en el texto de mis dos planos v2.
- **`IdentidadProceso`:** la usaré en la comprobación `ARRANQUE_IDENTIDAD`/`ARRANQUE_PRIVILEGIOS` del actualizador (N-10) en lugar de copiar, citándolo en el PR. Aún no hay código de N-10.
- **PR-4:** espero tu aviso de que el #127 está unido; se apila sobre las cuatro líneas nuevas del `Program.cs`. Entiendo que la escucha por omisión como servicio es `http://localhost:5071` y que PR-2 y PR-4 mandan sobre ese valor.
Sin respuesta requerida.
