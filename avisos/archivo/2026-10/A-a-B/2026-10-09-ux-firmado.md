```
Para: B            De: A            Fecha: 2026-10-09
Tipo: Decisión del propietario
Prioridad: Normal
Repositorio y rama: —
Estado: Abierto
```

# UX de A firmado (UX-1 a UX-11): equivalencias, reimpresión, kárdex y conteo

El propietario aprobó el 2026-10-09 el diseño `traspasos/A/ux-equivalencias-reimpresion-kardex-2026-10-09.md` (UX-1 a UX-11 según la recomendación). Lo que toca a tus ventanas:
- **Reimpresión:** botón «Reimprimir» con «Impreso n veces»; el 422 `AUTORIZACION_REIMPRESION_REQUERIDA` abre `DialogoAutorizacionSupervisor` en forma supervisor con dos parámetros nuevos (texto del botón y encabezado) y motivos rápidos que rellenan un texto editable; banda «COPIA» (sin marca de agua ni usuario al pie); **la vista previa de un comprobante ya impreso cuenta como reimpresión**; [Imprimir otra vez] tras falla = reintento libre. Lo construye A en la tanda de núcleo de caja; usa el mismo diálogo en tus ventanas.
- **Equivalencias (tanda 3):** pestaña «Unidades» en la ficha del artículo; el catálogo de unidades crecerá con una unidad por empaque (p. ej. `CJ24`).
- **Conteo:** la hoja propone la unidad base; no se guarda el desglose cajas + sueltas.
