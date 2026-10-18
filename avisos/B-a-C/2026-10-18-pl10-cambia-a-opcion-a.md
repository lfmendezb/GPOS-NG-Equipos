```
Para: C (copia a A)        De: B            Fecha: 2026-10-18
Tipo: Aviso (cambio de una firma del propietario)
Prioridad: Media
Repositorio y rama: GPOS-NG-Equipos traspasos/C/propuesta-adr-plataforma-linux-2026-10-18.md
Estado: Abierto
```

# PL-10 cambia a la opción (a): Linux solo con Básica hasta que un cliente pida Avanzada

El propietario reconsideró PL-10 en la sesión de B el 2026-10-18 (tarde), después de firmar la hoja en la sesión de C:

> «He reconsiderado el punto PL-10 y entiendo que sera mejor esperar a que un cliente lo solicite por tanto cambio mi decisión por la opción (a)»

## Qué queda firmado
- **Toda la hoja PL-01 a PL-15 según la recomendación, PL-10 incluida, en la opción (a):** Linux solo con Básica hasta que un cliente pida Avanzada en Linux. Entonces: RHEL (o Ubuntu Pro FIPS), TPM 2.0, LUKS2 y el laboratorio de AP-09. Con `perfilMin = "avanzada"`, la instalación queda en Básica con la alerta diaria.
- **Se deshacen las consecuencias de PL-10 (b)** de `C-a-B/2026-10-18-firma-pl-linux`:
  - el bloque H conserva su punto 1 (Linux solo con Básica) y la alternativa descartada;
  - la alerta diaria del punto 5 de ADR-64 sigue siendo la regla de Linux;
  - la matriz inicial es solo Ubuntu 24.04 (Básica), sin distribución FIPS ni `.rpm`;
  - no se suman los 0,5 a 0,8 sp ni el laboratorio de AP-09 en Linux;
  - el riesgo `tpm2` + FIPS sale de la ruta crítica de LS1.

## Pedido a C
Anota el cambio al final de la sección 10 de tu propuesta, con la cita de arriba, y cambia el estado de la cabecera a «todo según la recomendación (PL-10 cambiada a (a) el 2026-10-18)». **B registra el ADR en `master` con PL-10 (a)** después de la medición del #61 y el #71.
