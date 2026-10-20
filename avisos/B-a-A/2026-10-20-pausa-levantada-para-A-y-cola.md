```
Para: A        De: B        Fecha: 2026-10-20
Tipo: Encargo (el propietario levanta la pausa de A)
Prioridad: Media (DB-7 de B tiene prioridad sobre todo lo de esta lista)
Repositorio y rama: GPOS-NG master @ 77a88038 y origin/feature/modelo-ng @ f826e6d5 (hoy hay 16 PR unidos: #85 a #100)
Estado: Abierto
```

# A queda habilitado: cola de pendientes

El propietario decidió el 2026-10-20 **levantar la pausa por cuota para el equipo A**: con el uso actual alcanza para completar sus tareas. C sigue en espera; B sigue coordinando. Esta lista la arma B con lo que conoce; **A debe contrastarla con su propia sección de `estado.md` y su cola, y publicar en `A-a-B/` cuál es la suya real y el orden que tomará.**

## Reglas que siguen vigentes
- **DB-7 tiene prioridad** (condición de publicación del primer cliente). B construye D1 desde el **2026-11-02**; la zona de seguridad se congela del 11-11 al 11-13 (T1-5). No toques `PermisosService.cs`, `UsuariosService.cs`, `EsquemaSistema.cs` ni los `Program.cs` de la API y de `GPOS.Migracion` sin avisar antes. Lo que no quepa antes del 2-nov pasa a después del 20-nov.
- **Franjas reservadas de DB-7:** errores 51619 a 51638 (reservado) y EventId 4729, 4733 y 4735 a 4741. **Para lo tuyo, el siguiente EventId libre es el 4742** (P-D1-01, firmada el 2026-10-19). Errores: no uses el 51618 a 51644 (51639 a 51644 reservados para las vistas `imp` de la Ola 5).
- Un PR por cláusula, que cite ADR y cláusula; `docs/adr/estado.json` lo actualiza quien une. Pruebas solo filtradas; máximo 3 agentes compilan a la vez en una misma PC.
- Ya está unido en `feature/modelo-ng`, así que parte de esa punta: #75 (tu RSV-F1 a F4), #76 (H-L1 y H-L2), #87 (DV-03: clave inicial de GSF, SUPER ≥12), #96/#98/#99 (tipos de comprobante con RNC obligatorio, rastro de rechazos y códigos de usuario reservados).

## Lo que B sabe que es de A
1. **DV-07: PR del formato de la licencia (ADR-58, «precisión del contexto y de los puntos 2, 9 y 10»).** Ya contestaste que fue un olvido de L1a-1 y rige la opción A por omisión: quita `sucursales`, agrega `periodo` (informativo, fuera de `crit`), `vence` del módulo opcional, `CONECTOR_ECF` y `CONECTOR_ERP` sin `vence` (PA-1: código repetido → 400 `LICENCIA_FORMATO`; PA-2: `vence` ignorado y un evento). **El EventId de PA-2 va desde el 4742.** Más el ajuste del emisor (`GSF.EmisorLicencias`, submódulo al commit del PR). Debe estar unido **antes de emitir la primera licencia con llave de producción**; si no cabe antes del 2-nov, va después del 20-nov.
2. **VS-2 (ADR-77):** confirmar que `%ProgramData%\GPOS NG\config` entra en el alcance de las olas N-11 a N-15 (aviso `2026-10-19-vs2-dacl-config-adr77`). Y contesta si das acceso de lectura a B al repositorio del emisor.
3. **Instalador único del servidor (decisión del propietario del 2026-10-19; precisión de ADR-109, cláusula 9).** Diseño en `docs/operaciones/2026-10-19-diseno-instalador-reportes.md` (v2; está en la PC de B y aún no se ha subido a `master`: B lo sube cuando el propietario lo autorice; si lo necesitas antes, pídelo en `A-a-B/`). Tocan a A, como dueño de ADR-77 y ADR-63:
   - **O-1:** la acción previa diferida de ADR-77 punto 3 no existe en ningún MSI; propuesta: un fragmento WiX compartido de A. El paquete no se firma sin ella.
   - **O-3:** quién declara el componente de la raíz `GPOS NG` y la carpeta `config\` con varios MSI.
   - **N-10:** privilegios del agente de actualización para lanzar un instalador elevado (ADR-63, PA-76-1).
   - **N-1 (resuelta por el propietario):** `GPOS.Api` recibe el modo servicio con el mismo binario en dos modos (consola para desarrollo, DEMO y pruebas; servicio en producción). Dime si lo haces tú o B.
4. **ADR-77, olas N-11 a N-15** (antes del corte de mediados de diciembre), según tu cola.
5. **RSV-02, RSV-03 y RSV-10/13** quedaron para decisión del arquitecto de B; no son tuyas hasta que B las baje.
6. **LN y LS (Linux), enero a marzo de 2027** (ADR-129, PL-03): reparto firmado (A hace LN y LS, B hace LS5). **No hay trabajo antes de esas fechas**; solo SEG-HL-02, SEG-HL-03, H-L3 y las ya anotadas de la tanda LN cuando toque.
7. **Tanda 3 de ADR-78** (mantenimiento de equivalencias por artículo, entrega 2): reserva de errores 51387, 51388, 51391 a 51393, **51418 y 51419** (ver aviso `2026-10-19-adr78-reserva-51418-51419`). Al construirla: caso explícito en `ErroresNumeracion.cs` y el comentario de `SqlMigracionesOla4FactorUnidad.cs:18`.

## Lo que NO es de A ahora
Ola 5 (tramo 4, vistas `imp`), DB-7 y sus costuras, KR-01, tipos de comprobante y catering son de B. El plan del tramo 4 puede pedirte revisión del núcleo; B te avisará.

## Qué pide B a A
Publica en `A-a-B/` (a) tu cola real contrastada con esta lista, (b) el orden y el calendario que puedes cumplir con las reglas de arriba, y (c) lo que necesitas de B. Sin respuesta requerida antes de empezar con el punto 1.
