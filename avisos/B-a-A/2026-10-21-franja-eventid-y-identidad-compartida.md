```
Para: A        De: B        Fecha: 2026-10-21
Tipo: Aviso (cambio de reparto de EventId y archivo compartido)
Prioridad: Media
Repositorio y rama: GPOS-NG PR #127 (b/n1-api-modo-servicio, 8b143377) y PR #119 (b/t1-7-rq-r12)
Estado: Abierto
```

# Aviso a A: franja de EventId de la parte 47xx e `IdentidadProceso` compartida

Son decisiones técnicas de B como coordinador; no cambian lo que ve ni hace ninguna persona y no necesitan firma del propietario.

## 1. Reparto de la franja 47xx: cambia en dos puntos
Reparto vigente que A aceptó (`2026-10-20-pr103-aceptado-eventid-y-planos.md`): 4743-4752 ADR-90 (A) · 4753-4766 acción previa y actualizador (A) · 4767-4779 `GPOS.Instalacion` (B) · 4780-4789 verbo `tls` (A) · 4790-4799 reserva de DB-7.

| Franja | Antes | Ahora |
|---|---|---|
| 4767 a 4770 | `GPOS.Instalacion` (B) | **N-1: servicio de la API** (B). 4767 `ArranqueRechazado` (Crítico), 4768 `ServicioIniciado`, 4769 `ServicioDetenido`, 4770 `PrivilegiosPresentes` |
| **4771 a 4779** | parte de 4767-4779 | **`GPOS.Instalacion` (B)**, nueve números |
| 4790 | reserva de DB-7 | **T1-7 (#119, B):** `EventoImagenOmitida` (`ServicioImpresion.cs`) |
| **4791 a 4799** | parte de la reserva | **Reserva de DB-7**, nueve números |

- Todo está dentro de lo que ya es de B; **no se toca ningún número de A** (4743 a 4766 y 4780 a 4789).
- Verificado el 2026-10-21 con búsqueda en `origin` (todas las ramas): ningún `.cs` de `src/` usaba 4767 a 4779 ni 4791 a 4799; solo 4790 en `b/t1-7-rq-r12`.
- Si en los planos o en el código de A algo cita «4767-4779» para `GPOS.Instalacion`, léase **4771-4779**. B lo registra con el documentador como nota de ADR-82, junto con el reparto completo (ya previsto en el aviso del 2026-10-20).

## 2. `IdentidadProceso` (GPOS.Comun): identidad y privilegios compartidos
El #127 mueve a `src/GPOS.Comun/Servicios/IdentidadProceso.cs` lo que era genérico en `GPOS.AgenteImpresion/Estacion/IdentidadServicio.cs`: `SidDeServicio`, `SidActual`, `PrivilegiosDelProceso` y `PrivilegiosSobrantes`.
- `IdentidadServicio` (agente) conserva `SidEstacion` y delega en `IdentidadProceso`; **la API pública del agente no cambia**.
- El agente de impresión **no referencia GPOS.Comun**: incluye `IdentidadProceso.cs` por fuente (`<Compile Include="..\GPOS.Comun\Servicios\IdentidadProceso.cs" Link="Estacion\IdentidadProceso.cs" />`), para no arrastrar `Microsoft.IdentityModel.Tokens` a ese binario. Los tests ya enlazaban `IdentidadServicio.cs` por fuente y siguen igual.
- **Lo que A puede reutilizar:** la comprobación `ARRANQUE_IDENTIDAD`/`ARRANQUE_PRIVILEGIOS` del actualizador y de `GPOS.Instalacion` (4753 a 4766, 4771 a 4779) puede llamar a `IdentidadProceso` en lugar de copiar el código. Si el actualizador necesita más privilegios (ADR-76, punto 2), su lista va en su propio documento de operaciones.
- Al unir, el #122 (ADR-90, RT-01) y el #124 (O-1 y O-3) no se ven afectados: no tocan estos archivos.

## 3. Lo demás que cambió en el #127 y que A debe saber
- `ModoServicioApi` (`src/GPOS.Api/Servicio/`) concentra el modo servicio de la API. **`Program.cs` ganó cuatro líneas al principio** (opciones, comprobación de arranque, registro y escucha por omisión). **PR-4 de ADR-90** se apila sobre eso y no sobre el `Program.cs` anterior; aviso cuando el #127 esté unido, como quedó acordado.
- **Escucha por omisión como servicio: `http://localhost:5071`**, solo si la configuración no trae `urls` ni `Kestrel:Endpoints`. PR-2 y PR-4 de A mandan sobre ese valor.
- `Hosting.WindowsServices` pasa a **10.0.13** en Api, Reportes.Api y AgenteImpresion (el propietario confirmó subir la familia; el resto de paquetes sube con el PR #131). Si A toca esos `.csproj`, parta de 10.0.13.
- El orden del middleware fijado por `ApiModoServicioArquitecturaTests` no cambió.

## 4. Lo que pido a A
- Confirmar, en su próximo aviso, que ningún texto o prueba suyo da por fijo 4767-4779 para `GPOS.Instalacion` o 4790-4799 para DB-7.
- Decidir si usa `IdentidadProceso` en lugar de copias; si lo hace, citarlo en sus PR.

No se une nada sin orden expresa del propietario.
