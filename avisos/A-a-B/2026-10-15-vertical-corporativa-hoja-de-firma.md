```
Para: B        De: A                          Fecha: 2026-10-15
Tipo: Entrega
Prioridad: Media
Repositorio y rama: área común traspasos/A/hoja-firma-vertical-corporativa-2026-10-15.md (+ pos- y contable-vertical-corporativa-2026-10-15.md)
Estado: Abierto — H-01 a H-11 pendientes de firma; F-1 a F-4 firmadas
```

# Vertical Corporativa (comedor o cafetería interna): requerimiento y hoja de firma

## Origen
Pedido directo del propietario en la sesión de A (2026-10-15). Las citas literales están en la §1 de la hoja:
- es una vertical nueva, **Corporativa**, derivada de la Estándar;
- los empleados se identifican con carné y foto;
- hay una bolsa mensual de subsidio, el almuerzo y la cena al 100 % y artículos con el 50 % subsidiado;
- los consumos internos van sin NCF y los visitantes reciben NCF;
- la cafetería es de la empresa y la administra un tercero.

## Firmado por el propietario (F-1 a F-4, literal en la §3)
- **F-1 Horario:** algunos artículos tienen horario restringido y el sistema los bloquea fuera de él, como el almuerzo y la cena. La mayoría no tiene restricción.
- **F-2 Artículos al 50 %:** la mitad subsidiada se descuenta de la bolsa.
- **F-3 Bolsa:** se renueva cada mes y lo no usado no se acumula. Queda la precisión PF-3 para confirmar esta lectura.
- **F-4 Pago del empleado:** efectivo, tarjeta y nómina, combinables; cada empresa elige.

## Pendiente de firma: H-01 a H-11
- **H-01 Modelo de operación:** administración por cuenta de la empresa frente a concesión.
- **H-02 Capacidad común con la hoja de catering firmada el 2026-10-09:** se propone `CORPORATIVA` con `CARGO_EMPRESA`. **Precisa la forma de CE-04 y CE-06**, sin costo.
- **H-04 Porción que paga el empleado con su dinero:** la postura del propietario es «todo interno, sin NCF». El contable la califica de riesgo **Alto** y recomienda S-1, un E32 automático solo por esa porción, de unos 0,3 sp. La decide el propietario antes del primer cliente.

## Etapa
- **Nada en la entrega 1.** Va en la entrega 3, en un tramo propio después de la 3a.
- Unos 7,5 a 8,0 sp, o 6,8 sp con la capacidad común.
- **El diseño no se lanza hasta la firma:** datos → software y UX → seguridad.

## Para B
- **ADR-85 a 88 de A, en Propuesto:** la vertical y el ticket, los beneficios, el punto fiscal y la capacidad común.
- **La hoja de catering propone un ADR-126 que ya está ocupado en `master`.** Hay que renumerar al registrarla.
- **La §7 trae el correo para el contador de la empresa:** CF-1 y CC-06 a CC-13. Lo envía el propietario.
