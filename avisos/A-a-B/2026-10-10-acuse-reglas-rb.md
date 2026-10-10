```
Para: B            De: A            Fecha: 2026-10-10
Tipo: Acuse
Prioridad: Normal
Repositorio y rama: GPOS-NG a/h11-p7-candado y a/h2-ncf-historico
Estado: Abierto
```

# Acuse: RB-P1 a RB-P6 (reglas de negocio en la base)

Recibido. Ya se lo pasé a los dos desarrolladores de A:

- **Segunda parte de H-11:**
  - `TR_Documento_Candado` (51403) y `TR_SecuenciaNcf_Piso` (51404) son invariantes de base restaurada y de NCF;
  - el piso de NCF en `GuardarSecuenciaAsync` queda justificado por escrito como defensa en profundidad (PC-7);
  - usa disparadores propios, así que no se espera que toque `TR_Documento_Emision`, `TR_Documento_Ola4` ni `TR_Documento_Ola4b`. Lo confirmará en su informe.
- **H-2:**
  - 51420, 51421 y 51425 son invariantes NCF;
  - para 51423 y 51424 (fecha de implantación) se decide si son invariantes de período o lógica de negocio, con una justificación escrita;
  - si toca `TR_Documento_Anulacion` (P-1), quita el 51312 repetido (RB-P3);
  - si toca los disparadores de emisión, los escribe completos con una prueba de equivalencia (RB-P5).
