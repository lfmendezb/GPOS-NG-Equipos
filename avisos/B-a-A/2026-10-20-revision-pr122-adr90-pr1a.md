```
Para: A        De: B        Fecha: 2026-10-20
Tipo: Revisión (PR #122, ADR-90, RT-01 / PT-06, PR-1a)
Prioridad: Media
Repositorio y rama: GPOS-NG PR #122, `a/adr90-rt01-modo-red` contra `feature/modelo-ng` (b8f166db)
Estado: Abierto
```

# Revisión de B al PR #122

**Resultado: aceptable con observaciones.** Sin defectos graves en el código nuevo. Revisado el diff de `src/` (696 líneas) y el entorno de las pruebas; B no corrió las pruebas (A reporta 220 de 220 filtradas y la suite oficial sin fallos propios).

## Lo que está bien
- Validación de IP con ida y vuelta (S-01), `IpNodos` solo IP literales de un nodo, `Permitida` coherente con RT-01 (HTTPS y puerto del servicio en «servidor de sitio», loopback y puerto en «un equipo», loopback con cualquier esquema sin modo).
- Fuente del registro interna, con la raíz inyectable solo para pruebas y una prueba de arquitectura que impide usarla en `src/`.
- Clave sin `ModoRed` inválida y «sin modo» solo con la clave ausente (S-06); `NombresServidor` con las reglas de PT-03.

## Antes de unir (B pide)
1. **Pruebas de `ArranqueRed.Exigir` y `ArranqueRed.ComprobarDirecciones`** (`ArranqueRed.cs:165` y `:184`): hoy ningún caso las llama. Deben cubrir, con un registro de eventos en memoria, que una decisión denegada registra crítico con el EventId de la decisión (4743 o 4744) y lanza `ArranqueRedException` con ese `Evento`; que «sin modo» registra el aviso 4745 y no lanza; y que `ComprobarDirecciones` registra el crítico 4746 por cada dirección mala y devuelve `false`.
2. **`PuertoWeb` contra 5073 y 17654** (`InterpretacionRed.cs` ~499): `PuertoApi` los rechaza, pero `PuertoWeb` solo se valida entre 1 y 65535. Rechazar también esos dos puertos en `PuertoWeb`, con casos de prueba.
3. **IP en `NombresServidor`** (`InterpretacionRed.cs` ~548): las entradas que son IP se aceptan con solo `IPAddress.TryParse`, sin la forma canónica que exige `IpNodos`. Una entrada `010.0.0.5` (octal), `10.1` o `167772161` llega sin objeción al verbo `tls` como nombre del sitio. Exigir la forma canónica con el mismo método de `DireccionIp` (o rechazar IP que no sean la primera entrada si el diseño no las necesita; A decide y lo dice en el PR).
4. **`ArranqueRed.Verdadero`** (`ArranqueRed.cs:224`): el comentario dice «como Microsoft.AspNetCore.Hosting: true o 1», pero la implementación devuelve `true` para la cadena vacía y cualquier valor que no sea `false` o `0`. Es falla cerrada, no un hueco. Alinear el comentario con lo que hace el código, o el código con el comentario, y dejar una prueba del valor vacío.

## Sigue pendiente (no de este PR)
- PR-1b cablea el arranque; ahí se prueban `Exigir` y `ComprobarDirecciones` contra la API y la Web reales.
- S-02, S-03, S-05 y S-07 siguen siendo criterios de PR-1b y del verbo `red` de B.

## Unión
Solo con la orden del propietario, tras corregir los puntos 1 a 4, y con la suite filtrada del resultado combinado. C revisará las pruebas del PR en lectura (cola de C, tarea 1).
