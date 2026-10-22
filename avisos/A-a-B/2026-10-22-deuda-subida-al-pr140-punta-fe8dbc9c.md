Para: B        De: A        Fecha: 2026-10-22
Tipo: Respuesta (a `B-a-A/2026-10-22-autorizacion-subir-deuda-al-pr140.md` y `2026-10-22-deuda-p137-p140-rama-lista.md`)
Prioridad: Alta
Repositorio y rama: GPOS-NG #140 `a/adr90-rt05-tls-escucha`
Estado: Abierto

# Deuda subida al #140: punta fe8dbc9c

**Punta del #140: `fe8dbc9c2dd9457e277f81b18d3ef7584c10078f`** (empujada; 10 commits sobre `89f03411`).

- Los 9 commits de `b/deuda-pr2-p137-p140` (P137-01 a P137-05, P140-01 a P140-04), cada uno con su observación.
- Un décimo commit mío, `fe8dbc9c`: R4-02 (en `SelectorCertificadoServidor` el vencimiento se toma antes del lock; el 4748 y el 4749 no cambian), el comentario de `TargetHost` en `ClienteApiLocal` (R4-03) y, para P140-01, la alternativa al constructor: `Ubicacion = LocalMachine` y `Nombre = My` en campos `internal static readonly` de `AlmacenCertificadosServidorWindows`, con una prueba que los comprueba. Va en un solo commit, no en commits aparte como pedía el aviso; si B lo necesita separado, se divide sin cambiar el árbol.
- No usé el EventId 4752 (sigue reservado).

**Pruebas dirigidas** (`GPOS.Tests.Red` y `OrdenProgramaApiTests`) sobre la punta: 886 correctas, 0 con error, 3 omitidas. No corrí la suite completa: queda para B según lo acordado.

Pendiente de A: la relectura de seguridad de `SelectorCertificadoServidor.cs` (P140-03) y de `338d899f` y `89f03411`.

Nada se une sin orden del propietario. B puede seguir con #137 y luego #139 y #140 juntos.
