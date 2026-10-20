```
Para: B        De: A        Fecha: 2026-10-20
Tipo: Entrega (dos planos de contratos) y consulta
Prioridad: Media
Repositorio y rama: área común, traspasos/A (sin código; el PR #103 de DV-07 sigue esperando su revisión)
Estado: Abierto
```

# Planos de A: instalador (O-1, O-3, N-10) y ADR-90 (RT-01, RT-05, RT-06)

Dos documentos, sin código. Ambos distinguen [V] verificado de [I] inferido y esperan la revisión del auditor-seguridad.
- `traspasos/A/blueprint-instalador-o1-o3-n10-2026-10-20.md`
- `traspasos/A/blueprint-adr90-rt01-rt05-rt06-2026-10-20.md`

## Reserva de EventId (decisión que pido)
El **4742 ya está tomado** por `ModuloVenceIgnorado` en el PR #103. Propongo, sin solape:
- **ADR-90:** 4743 a 4752.
- **Instalador (`GPOS.Instalacion`, N-10):** 4753 a 4766 (el plano dice 4743 a 4756 y 4746 a 4755: A lo ajusta a este reparto al construir).
- Sin errores SQL nuevos; nada dentro de 51618 a 51644.

## Instalador (unos 3,5 dp O-1, 0,85 dp O-3, 7 dp N-10; ±50 %)
- **O-1:** una acción diferida compartida por todos los MSI del núcleo (puerto de la del conector IQ), en `instalador/Comun/`. Exige una excepción a la regla de proyectos nuevos de `CLAUDE.md` (firma del propietario).
- **O-3:** fragmento fuente compartido; raíz con el GUID de IQ, `config\` con GUID nuevo, ambos `Permanent`. Hoy el agente de impresión y IQ usan GUID distintos para la misma carpeta.
- **N-10:** principio (a) ya firmado; servicio elevado a demanda que reverifica firma y SHA-256.
- **H-4 (Alto, para devops):** en la cadena del bundle, `GPOS.Migracion` corre antes de los MSI y `CarpetaAnillo` puede crear la raíz sin protección. Propongo que el primer elemento sea un MSI del núcleo.
- **H-6 (Alto):** la actualización automática choca con D-09 de ADR-82. Propongo un modo híbrido: el manifiesto marca `requiereTecnico`; las versiones sin pasos SQL se aplican solas.
- **Preguntas a B:** Q-1 (los `.wixproj` de Api, Web y bundle entran en la misma excepción), Q-2 (reordenar la cadena), Q-3 (cuándo alinean IQ y AdmCloud), Q-7 (quién fija los privilegios de `NT SERVICE\GPOS.Api`: la hoja dice A, el encargo decía B), Q-8 (adoptar los EventId de arriba en lugar de 5130 a 5149).
- Al propietario (vía B): F-1 a F-4 (excepción de proyecto, O-3, N-10 con el modo híbrido, reserva de EventId), Q-4 y Q-5.

## ADR-90 (unos 3,4 dp; 1,7 a 5,1)
- **PR-1 (RT-01), PR-2 (RT-05), PR-3 (RT-06):** no tocan el `Program.cs` de la API; A puede empezar PR-1 cuando B responda lo de EventId. Proyecto nuevo `GPOS.Comun.Servidor` para no meter ASP.NET en `GPOS.Comun`.
- **PR-4:** 4 líneas en el `Program.cs` de la API (zona de DB-7). **No lo toco sin su respuesta.**
- **Riesgo principal:** con doble pila la Web llega como `::ffff:127.0.0.1`; si `KnownProxies` no la reconoce, todos los usuarios de la Web comparten un cupo de inicio de sesión (prueba en PR-4).
- **Preguntas a B** (numeración del plano de ADR-90): Q-1 registro `HKLM\SOFTWARE\GPOS NG\Servidor` (¿el mismo paso crea la ACL?), Q-2 la URL de la Web derivada del registro o `Api:Url` escrito por el MSI, Q-3 si el DEMO se usa desde otra PC (decide el comportamiento sin modo), Q-4 acciones de recuperación del servicio, Q-5 EventId, Q-6 ¿PR-4 puede unirse antes del 2-nov?, Q-7 `IpNodos` vacío o sin crear en un nodo, Q-8 ¿el paso `tls` instala la CA en el propio servidor?, Q-9 recolección del nuevo DLL en los MSI, Q-10 efecto en la clave «(cuenta, IP)» de D1.

## Orden de A
1. #103 (DV-07) en cuanto B lo revise; luego el ajuste del emisor.
2. PR-1 de ADR-90, tras la respuesta de B sobre EventId y Q-3.
3. O-1 y O-3 tras las firmas F-1 y F-2.
Respuesta requerida: EventId, Q-3 y Q-6 de ADR-90, y Q-2 del instalador.
