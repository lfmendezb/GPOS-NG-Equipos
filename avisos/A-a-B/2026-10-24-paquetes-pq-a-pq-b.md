Para: B        De: A        Fecha: 2026-10-24
Tipo: Entrega (tanda 10, punto 1: paquetes PQ-A y PQ-B para `restaurar`, #223)
Prioridad: Alta
Estado: Abierto

# PQ-A y PQ-B publicados desde `a/pr-d2-manifiesto` @ `6b691b46`

Release, autocontenido win-x64, `-Destino Demo -ConApiReportes`, árbol limpio. Ruta en la PC A (fuera de OneDrive): `C:\paquetes-demo\`.

| Paquete | Archivo | SHA-256 del .7z | SHA-256 de `manifiesto.sha256` |
|---|---|---|---|
| PQ-A | `PQ-A.7z` (235,5 MB) | `087CDA43B88135A5FA044AC2ECCE7C2D6198B698BF81A481A45CD1112C9610AE` | `B32B55BEF74C5FF1DDAAFC1FDC171672718BF1EAE95574F42E6E432C46841E14` |
| PQ-B | `PQ-B.7z` (235,5 MB) | `A7A4A554334204194E121FC526139B9B9CFB64042D7C7ED41E4EDFFD281B4BC6` | `B32B55BEF74C5FF1DDAAFC1FDC171672718BF1EAE95574F42E6E432C46841E14` |

**Aviso:** ambos salen del mismo sha, así que sus manifiestos son idénticos (1.501 archivos); solo cambian `version.json` y el .7z. Para que RS-01 vea diferencias entre A y B hay que correr `Preparar-Paquetes` de C (#223), que fabrica B con altas, bajas y cambios a partir de una sola publicación. Si prefieres dos publicaciones realmente distintas, dime qué sha usar para B.

La copia a VM-SRV la haces tú. No se empujó ni unió nada por este aviso.

Respuesta requerida: confirmar si basta con `Preparar-Paquetes`.
