```
Para: B        De: C            Fecha: 2026-10-20
Tipo: Entrega (cola de C, tarea 3); cierra la cola 1 a 4
Prioridad: Media
Repositorio y rama: GPOS-NG c/pruebas-inestables-r02-super-dl22 @ 73fbdf78, PR #125 contra feature/modelo-ng
Estado: Abierto
```

# Entrega: pruebas inestables (PR #125)

[#125](https://github.com/lfmendezb/GPOS-NG/pull/125) cambia solo pruebas, sin código de producción, con un commit por causa. El informe está en `traspasos/C/2026-10-20-diagnostico-pruebas-inestables.md`.

| Prueba | Causa [I] | Arreglo | Comprobación en C |
|---|---|---|---|
| R02 | La diferencia de `execution_count` da 0 o negativa si el plan sale de la caché o se recompila. Reproducido vaciando la caché: `Expected 1, Actual -21` | Repite la medición hasta 5 ventas mientras la diferencia no sea positiva | 2/2 cinco veces seguidas, también con la caché vaciada |
| Super inhabilitado | AJENA no tiene base: el 4060 obliga a consultar `master` con un solo reintento (PC3-02), y bajo carga responde 400 «No se pudo conectar». Producción hace lo correcto | `EntrarSinTransporteAsync` repite solo ese 400 exacto (criterio de `ProbarSinTransporteAsync` de A) | 8/8 tres veces seguidas |
| DL22_S18 | El tope de 1,5 s medía también el inicio de sesión físico (`ConnectTimeout=3`) y un reintento | No se sube el tope: espera el intervalo más 100 ms y exige la primera lectura en null. Se comprobó que la prueba falla si se quita `AND Inhabilitado = 0` | 14/14 dos veces seguidas |

**Para B:**
- La validación bajo carga solo se puede hacer en su suite. Si alguna prueba vuelve a fallar, C necesita el mensaje literal.
- `DL22_S18` es `[FactModoMixto]`: en una instancia que solo admite autenticación de Windows se omite.

## La cola de C del 2026-10-20 queda completa
| Tarea | Entrega |
|---|---|
| 1 | Revisión de pruebas de los PR #119 a #122: informes y comentarios publicados |
| 2 | PR #123: `DrillDownTests` |
| 3 | PR #125: pruebas inestables |
| 4 | Plan de pruebas de DB-7 D1 (P-1 a P-9 para B) |

C queda sin trabajo en curso.
