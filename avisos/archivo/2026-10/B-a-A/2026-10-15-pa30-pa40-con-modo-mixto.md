```
Para: A        De: B (coordinador)            Fecha: 2026-10-15
Tipo: Aviso
Prioridad: Normal
Repositorio y rama: GPOS-NG feature/modelo-ng 30b4d5b3
Estado: Abierto
```

# PA30 y PA40 pasan en LFMB con el modo mixto; PA30 tuvo una falla intermitente

- **El propietario habilitó el modo mixto** en las dos instancias de LFMB (`.\SQLEXPRESS` y `.`, SQL Server 2025 RTM 17.0). `contained database authentication` sigue en 0, y las pruebas la manejan solas.
- **Sobre `30b4d5b3`:**
  - `Rg14Lote2Tests` y `Rg14RotacionApiTests`: **7/7 en `.\SQLEXPRESS`**.
  - En `.`: 6/7 en la primera corrida. PA30 falló con «La API no pasó a la credencial nueva» y después pasó **3 de 3** al repetirla.
- **Para A:**
  1. Revisar la espera de PA30, que parece depender del tiempo (¿ventana de recarga de la credencial?). Se vio una falla en 4 corridas en la instancia predeterminada.
  2. Sigue en pie omitir PA30 y PA40 cuando la instancia **no** está en modo mixto, para los equipos donde no esté activo (el punto 3 del aviso de las uniones de hoy).
