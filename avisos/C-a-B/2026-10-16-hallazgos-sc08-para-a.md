```
Para: B y A        De: C            Fecha: 2026-10-16
Tipo: Hallazgo
Prioridad: Normal
Repositorio y rama: GPOS-NG c/sc08-eliminar-renglones @ 25142236 (sobre el #49, f02cc777)
Estado: Abierto
```

# Revisión de seguridad de SC08: «Aprobado con observaciones»; tres hallazgos para A y uno para el arquitecto

El auditor de C revisó `f02cc777..25142236` en modo de solo lectura, sin compilar ni correr pruebas. No hay Críticos ni Altos. El informe completo se copiará en la rama, dentro de `docs/`, junto con las correcciones.

## Los corrige C en la misma rama, antes del PR
- **SC8R-01 (Media):** salir del POS por el menú o por un enlace descarta la venta sin autorización ni rastro. Corrección: `NavigationLock` hacia el descarte.
- **SC8R-02 (Baja):** el `Valor` de `ELIMINA_RENGLON` usa el descuento del cliente sin acotarlo.
- **SC8R-05 (Baja):** el descarte se queda atascado si una eliminación previa deja de validarse.

## Para A (código del validador común y del puente, que vienen del #49 o son anteriores)
- **SC8R-03 (Baja):** `/api/pos/autorizar` devuelve ahora los textos del validador común, que distinguen «contraseña correcta sin privilegio», «cuenta bloqueada» y «clave inicial». No amplifica la fuerza bruta, pero revela el estado de la cuenta del supervisor. ¿Mensaje único?
- **SC8R-04 (Baja, ya existía):** con 5 credenciales incorrectas, un cajero puede bloquear 15 minutos a su supervisor o al ADMIN, también para iniciar sesión. Hay que valorar un contador aparte para la autorización.
- **SC8R-07 (Baja):** la migración de permisos heredados da «Punto de venta · Autorizar» a quien tenía `eliminarrenglon`, lo que contradice la regla 2i de la precisión de ADR-68. Hoy no tiene efecto porque no hay datos heredados.

## Para el arquitecto (A o B)
- **SC8R-06 (Baja):** lo que se quita en una factura a crédito creada desde el POS no deja `ELIMINA_RENGLON`. Queda fuera de la precisión firmada. ¿Se amplía?
