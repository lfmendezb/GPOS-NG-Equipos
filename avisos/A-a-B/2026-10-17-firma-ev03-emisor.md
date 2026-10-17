```
Para: B y C        De: A            Fecha: 2026-10-17
Tipo: Aviso (firma registrada) y Entrega
Prioridad: Normal
Repositorio y rama: GSF.EmisorLicencias main @ b125760 (solo local, sin remoto)
Estado: Abierto: B la registra
```

# Firma del propietario en la sesión de A: EV-03 (a), ya construida en el emisor

**Respuesta literal:** «Firmo EV-03 (a): el emisor rechaza firmar con s2 cuando la hora NTP está fuera de [desde, hasta] de la autorización.»

## Qué decide
Es una política del emisor sobre el uso de la llave latente `s2` con una autorización de regreso de nivel (`autNivel`). Origen: EV-03 de la revisión de seguridad del emisor (`traspasos/A/revision-seguridad-emisor-verificarcompacto-2026-10-17.md`).
- **Antes:** el emisor no impedía firmar antes de `desde`, y la API aceptaba la licencia si se cargaba dentro de la ventana.
- **Por qué importa:** no alargaba la vigencia, pero el registro mostraba usos de `s2` anteriores a la causa que los autorizó. En un escenario `SospechaEquipoEmisor`, esa es justo la señal que interesa.
- **Ahora:** solo se firma con `s2` cuando la hora NTP está dentro de `[desde, hasta]`.

## Entrega
- **`06d153e`:** `ComprobarLicenciaConAutorizacion` rechaza con `AUTORIZACION_INVALIDA` una hora NTP anterior a `desde`. La cota superior ya usaba la hora NTP.
- **`b125760`:** README con la compilación verificada (DLL Release `b944717d…80f6`).
- **Pruebas:** 95/95 en Debug y en Release. Una prueba nueva cubre la firma 1 s antes y 3 días antes, y los dos bordes.

## Para B
- Registrar la política: en ADR-60 o donde corresponda la regla 9.2 del emisor.
- **Sigue pendiente:** un remoto privado para `GSF.EmisorLicencias`. Sus commits solo existen en la PC A.

**Con esto, A no tiene firmas pendientes.**
