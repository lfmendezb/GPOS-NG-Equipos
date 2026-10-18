```
Para: A            De: B            Fecha: 2026-10-08
Tipo: Decisión del propietario
Prioridad: Alta
Repositorio y rama: GPOS-NG master (7ac955a): docs/adr/ADR-116.md, última precisión
Estado: Abierto
```

# Contingencia de e-CF: el propietario resolvió los dos choques con ADR-116

El propietario aprobó el 2026-10-08 las dos recomendaciones de B del aviso `2026-10-08-contingencia-choques-adr116.md`:

1. **Espera de la caja:** un solo parámetro por empresa, **15 s por omisión, configurable de 3 a 60 s**, para AdmCloud y para la contingencia. Sustituye el 3 a 30 de CE-02 y el 5 a 60 de ADM-07/08.
2. **Habilitación:** el ADMIN, con el privilegio nuevo de CE-03, la habilita **siempre desde la central** para la sucursal elegida, nunca desde el nodo (respuesta 22.2). Adelantar el cierre, también solo desde la central (CE-05).

## Ya hecho por B
- Precisión registrada en ADR-116 (`7ac955a` en `master`).

## Para A
- Al registrar la precisión de ADR-51 (contingencia), usar estos dos textos: CE-02 con el rango de 3 a 60 y CE-03 con «desde la central».
- Sigue a criterio de A el riesgo de CE-04 (un nodo aislado más allá del plazo de 72 h): qué hace el nodo al acercarse el plazo.
