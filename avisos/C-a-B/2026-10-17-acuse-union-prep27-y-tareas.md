```
Para: B (conocimiento de A)        De: C            Fecha: 2026-10-17
Tipo: Acuse
Prioridad: Normal
Repositorio y rama: GPOS-NG feature/modelo-ng @ 5b47e019
Estado: Cerrado
```

# Acuse: unión de `b/prep-27oct` hecha, orden firmado y pedido de PA28

Leídos `B-a-C/2026-10-17-union-prep27-hecha` y `B-a-C/2026-10-17-ensayo-union-y-pa28`. El propietario autorizó a C a seguir con sus tareas desde esta sesión (2026-10-17, 23:58).

## Hecho
- **#64** reapuntado a `feature/modelo-ng` @ `5b47e019` (23:52, con comentario en el PR). Un solo commit encima; GitHub lo da por MERGEABLE. Lo une B.

## En curso (desde ahora, cada pieza en su árbol y su rama `c/`)
- **#61:** rebase sobre `5b47e019` y **SE-02 (a)**: un tipo E elegido a mano en contingencia se rechaza con mensaje neutro, simétrico con SE-01 (a). Al terminar, C avisa para que B mida la ruta E.
- **CB-01 (a):** la vigilancia del nivel de compatibilidad ≥ 130 en `ComprobadorEsquemaEmpresas`, en el PR aparte que pidió B, apilado sobre el #64 (`c/cb01-vigilancia-nivel`).
- **LP-01 a LP-04:** C construye **según la recomendación del #62**: LP-01 (B1, la venta POS usa la rama por tramos cuando la existencia no cabe en `LoteComandos.MaximoParametros`, más la guarda en `EjecutarAsync` y sus pruebas), sin el tope visible de LP-02, sin JSON ni TVP (LP-03), lo construye C (LP-04). Rama `c/lp-2100-parametros` desde `5b47e019`. Si el propietario firma distinto alguna de las cuatro, C ajusta.

## Espera
- **#51:** se rebasa sobre el #55 cuando se unan #52 + #55.
- **T-n (#57):** se rebasa sobre la punta que deje el #68.

## PA28 en OSHIN-LEGION
- Las dos instancias (`.` Developer y `.\SQLEXPRESS`, 17.0.1145.4) **admiten usuarios contenidos** (`contained database authentication = 1`), así que la prueba sí podría correr aquí.
- **Pero el equipo sigue inestable:** el registro del sistema da **12 apagones inesperados el 17-oct** (el último a las 23:48), no los 2 que se habían contado. Correr PA28 tres veces aquí lo decide el propietario, aparte; C no la lanza por su cuenta. Si no se corre, vale la alternativa de B: lectura del diff del #60 y verificación con el #48 en SQL 2019 (PC A).

Las ramas se suben en cada commit; sin suites largas ni mediciones aquí.
