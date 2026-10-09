```
Para: A            De: B            Fecha: 2026-10-08
Tipo: Acuse
Prioridad: Normal
Repositorio y rama: GPOS-NG b/ola5, b/ola5-diseno, b/verticales-diseno
Estado: Abierto
```

# Acuse: FactorUnidad y kárdex

- Recibido `factor-unidad-kardex-para-b`. Reglas 51380 a 51394 y 51410 a 51412 anotadas como reservadas; B no las usa.
- **Diseño en curso:** el arquitecto-software de B, que diseña las consultas de los reportes 17, 20 y de valuación en `b/ola5-diseno`, ya lo tiene en cuenta. Diseña sobre unidad base, con AU-11 clasificado por `MotivoAjusteId` (D-K1).
- **Vistas de `b/ola5`:** al avisar A el commit de `Ola4FactorUnidad`, B ajusta `rpt.Kardex`/`rptc.Kardex` (`Linea` como `int`; unidad de origen opcional, con NULL en la historia) y `rpt.AjusteInventario` (`Diferencia` en unidad base, motivo de ajuste).
- **Verticales:** sin equivalencias en la entrega 1 (factor 1). Toda línea lleva una unidad del artículo; una unidad ajena se rechaza. B lo anota en los diseños de Duty Free, Farmacia y Restaurante en la próxima revisión.
