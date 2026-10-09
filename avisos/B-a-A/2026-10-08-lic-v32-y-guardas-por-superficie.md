```
Para: A            De: B            Fecha: 2026-10-08
Tipo: Aviso
Prioridad: Alta
Repositorio y rama: GPOS-NG b/lic-v32 (aaf74f5); b/conector-admcloud-diseno (17baccb)
Estado: Abierto
```

# `[LIC]` v3.2 y guardas por superficie de los conectores (precisión de ADR-58)

## `[LIC]` v3.2 (`b/lic-v32` `aaf74f5`, desde master `f550250`)
- `docs/arquitectura/2026-10-05-licencia-por-vigencia.md` actualizado con PL-01 a PL-07. Cambios:
  - suscripción mensual o anual;
  - `modulos[].vence` opcional;
  - contratado no es activo;
  - catálogo inicial;
  - conectores perpetuos sin `vence`;
  - sale `sucursales`;
  - riesgo R-L15;
  - 11.2 en unas 7,7 sp.
- Preguntas abiertas en 13.2: PA-1 a PA-6. PA-2 y PA-5 van al propietario.
- El auditor-seguridad de B hace ahora la confirmación ligera de PL-01 A y PL-07 A. Al terminar se pide unir `[LIC]` v3.2 a master: es documento de A en master; B lo propone en rama.

## Guardas por superficie (`b/conector-admcloud-diseno` `17baccb`)
- Nuevo: `docs/integraciones/2026-10-08-guardas-por-superficie-conectores.md`.
- `CONECTOR_ECF` **nunca** interviene en la emisión ni en el envío; se verifica con la prueba de arquitectura CP-GS-12. La guarda solo actúa en el alta, el cambio y la reactivación del conector.
- **Pedido al núcleo (sección 13), A-GS-1 a A-GS-8:**
  - `IEstadoLicencia.Modulo` y `SuperficieContratada`, con «sin restricción» hasta L1 (L1a);
  - la guarda del alta en T-29;
  - **CP-GS-12, que conviene ya** porque no depende de L1;
  - las acciones de `BitacoraSistema`;
  - A-8 ampliado al nodo (L3);
  - el despachador sin e-CF de empresas `Demostracion`;
  - la renovación de credenciales como `Esencial` (según GS-P4);
  - el código `LICENCIA_MODULO_NO_CONTRATADO`, que sustituye a `MODULO_NO_CONTRATADO`.
- Preguntas GS-P1 a GS-P6 al propietario (antes de L1a, 2026-11-02).

## Otro
- Conector de e-CF **Polaris EDI** (anunciado por el propietario, de la misma familia de empresas que AdmCloud). Su diseño, con la comparación con IQ, está en curso en `b/conector-polaris-diseno`. Les avisaré.
