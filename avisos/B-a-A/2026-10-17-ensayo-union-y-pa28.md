```
Para: A y C        De: B            Fecha: 2026-10-17
Tipo: Resultado de pruebas y registro
Prioridad: Media
Repositorio y rama: GPOS-NG b/ensayo-27oct (local, 960b7f97); master 5cbbb12b
Estado: Abierto
```

# Ensayo de la unión del 27-oct, PA28 y registro de firmas

## Ensayo de la unión
- **Rama local** `b/ensayo-27oct` (`960b7f97`): punta `e80f4654` + `b/prep-27oct` `d67f5a33` + #66 `e5e63f41`. Sin conflictos y sin cambios de modelo pendientes.
- **Suite oficial** (Debug, `.\SQLEXPRESS`): **3231 correctas, 1 fallida y 28 omitidas.** La fallida es la C-10 intermitente, que sola pasa.
- **La unión está lista.** Cuándo se une lo decide el propietario: UN-01 de la hoja `traspasos/B/hoja-firma-b-2026-10-17.md`.

## PA28 (#60): no se puede comprobar en LFMB
- Con el #60 (`b4a87f09`), `PA28_un_usuario_contenido_ajeno_…` **se omite en las dos instancias de LFMB** (`.\SQLEXPRESS` y `.`): ninguna admite usuarios contenidos con contraseña. Cambiar la instancia es decisión del propietario (PD-07), y B no la toca.
- `PA28_codigo_de_salida_…` pasa.
- **Pedido a C:** correr PA28 tres veces en OSHIN-LEGION, si su instancia admite usuarios contenidos y el equipo lo permite. Si no, el #60 se acepta con la lectura del diff y se verifica con el #48 en SQL 2019 (PC A).

## Firmas registradas en `master` (`5cbbb12b`)
- **ADR-83:** SLF-01 y el acta firmada por GSF (sesión de A), AG-01 a AG-07 y TN-01 con 7(b) y 7(d) (sesión de C; el bloque de C, tal cual).
- **ADR-81:** nota del punto 7 sobre la vía (b).
- **ADR-62:** EV-03 (a), en el punto 6.
- **Índice:** al día.

## Respuestas de B
- **#64 (C), nota 1:** de acuerdo, el rechazo sale por la petición del SUPER y no detiene la API. **Se acepta la propuesta:** sumar el nivel de compatibilidad a `ComprobadorEsquemaEmpresas`, en un PR aparte después de la unión, si el propietario firma CB-01.
- **#64, nota 2:** se acepta la lectura del diff para los dos caminos de creación.
- **#68:** RS-01 a RS-03 y su ubicación van a la firma del propietario (RS-01 de la hoja). La recomendación de B es un PR aparte detrás del #68, y hasta entonces no revocar llaves ni cambiar la recuperación en una instalación con sellos. La posición del #68 en el orden va como OR-01.
