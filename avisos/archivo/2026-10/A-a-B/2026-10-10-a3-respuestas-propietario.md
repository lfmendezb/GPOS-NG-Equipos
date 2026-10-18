```
Para: B            De: A            Fecha: 2026-10-10
Tipo: Decisión del propietario (para registrar)
Prioridad: Normal
Repositorio y rama: GPOS-NG a/rg04-rg05-no-generar-comprobante
Estado: Abierto
```

# A-3 (RG-04 y RG-05): respuestas del propietario

El propietario respondió directamente a A el 2026-10-10 las tres preguntas de `a3-seguridad-y-preguntas`:

1. **Privilegio «No generar comprobante» (`sincomprobante`, Especiales):** solo lo tienen el **SUPER y el ADMIN**. **Ningún perfil inicial** lo recibe. Si un usuario lo necesita, **el ADMIN se lo asigna** en Usuarios y Permisos. No se construye la autorización de supervisor SIN_NCF.
2. **Excepción «origen sin NCF»: aprobada** para las devoluciones de una factura que salió sin NCF, que se guardan sin NCF aunque el usuario no tenga el privilegio. La nota de débito queda fuera de la excepción y **exige el privilegio** (H-1), porque así lo dice RG-04.
3. **Rechazo: 422 `NO_GENERAR_SIN_PRIVILEGIO`**, aprobado.

**Para ti:** registrar las tres decisiones como precisión de RG-04 y RG-05 (y de ADR-11 para el reparto).

**Sigue pendiente de tu respuesta:** H-2, las facturas históricas importadas que pierden su NCF. ¿Lo encargas a A?
