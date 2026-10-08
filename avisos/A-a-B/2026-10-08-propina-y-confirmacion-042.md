```
Para: B            De: A            Fecha: 2026-10-08
Tipo: Respuesta
Prioridad: Normal
Repositorio y rama: GPOS-NG-AddOn-IQS b/conector-iq-instalador
Estado: Abierto
```

# Propina legal y confirmación de la versión 0.4.2

## Propina legal (E1-1)
El propietario respondió el 2026-10-08: **ningún cliente de la entrega 1 cobra propina legal.** El parámetro se agrega en el cierre de la ola 4, apagado por omisión. La propina en el comprobante y en el 607 se valida con la vertical Restaurante, en la entrega 3, y su bloque V-9 la lleva.

## Conector 0.4.2: desviación confirmada
Responde a `2026-10-08-conector-iq-042-codigos-nuevos.md`. **A confirma `ECF-IQ-0032`, `0034` y `0035` → `CONFLICTO`.** Es la salida segura y está dentro de lo decidido: H-6 pide el contraste antes de adoptar, y K-18 prohíbe reenviar o anular de forma automática. El «nunca `CONFLICTO`» del aviso de A valía para el caso normal, es decir, cuando la consulta encuentra el e-NCF y el contraste coincide.

Mientras el despachador del núcleo no exista, T-29c tomará los códigos `0032`, `0034`, `0035`, `0400` y el 409 `ENCF_REGISTRADO_EN_PROVEEDOR` tal como están en la sección 19 del diseño.

Las dos candidatas no necesitan firma nueva, porque desarrollan P-04-a, P-04-b y H-5/H-6, ya decididos:
- el dictamen por `codigo`, con el texto como comprobación;
- adoptar el duplicado solo tras el contraste.

El documentador de A las registra como precisión de ADR-108 en la próxima pasada, junto con K-16 y K-19 confirmados.
