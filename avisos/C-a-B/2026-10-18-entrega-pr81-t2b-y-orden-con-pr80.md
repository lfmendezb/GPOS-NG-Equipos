```
Para: B (conocimiento de A)        De: C            Fecha: 2026-10-18
Tipo: Entrega y nota de orden de unión
Prioridad: Media
Repositorio y rama: GPOS-NG c/t2b-archivo-instalacion → feature/modelo-ng (sobre 322b21d6)
Estado: Abierto
```

# Entrega: PR #81, T2 (b) de ADR-126 (archivo de instalación y guiones del DEMO)

## Orden de unión: primero el #80, después el #81
El #81 hace que la `Url` del archivo de instalación llegue de verdad a la configuración (la revisión de seguridad halló que antes quedaba por debajo de `appsettings.json`: S03). El tope de descarga del padrón (200 MB, `MaxMegas`) y el registro del host (S02) están en el **#80**. Si se une el #81 sin el #80, el padrón se descarga sin tope. Los dos tocan `Program.cs` de la API en líneas distintas.

## Qué trae
- `GPOS.Comun/Configuracion/ArchivoInstalacion` en los cuatro procesos. **Solo claves permitidas** (hoy `GPOS:RncDgii`), por decisión del propietario de hoy; sin secretos por construcción.
- Un JSON inválido no impide arrancar (S01). La carpeta puede cambiarse con una ruta absoluta.
- DEMO: variable de carpeta en la API, la Web y todo comando de Migración; ejemplo inactivo y LEEME.
- D-01: `miempresa.com` → `example.com`, con 4 excepciones menos en la guarda.

## Revisiones (T2 pedía devops y seguridad)
- **Seguridad:** Aprobado con observaciones. S01, S03 y S06 corregidas en el #81; S02 en el #80.
  - **S05, S04 y S07, para B:** S05 es una ventana teórica al recargar; S04, los cambios en caliente sin rastro; S07, `ventas@empresa.com` en `Importaciones.cs:180`, fuera del alcance de D-01.
- **Devops:** Listo con observaciones; las tres, corregidas.
- Informes en `traspasos/C/revision-seguridad-t2b-archivo-instalacion-2026-10-18.md` y `revision-devops-t2b-demo-2026-10-18.md`.

## Pendiente de T2
- **DACL y dueño del archivo:** requiere ADR-77 en el núcleo. Hoy `%ProgramData%` hereda permisos de escritura de fábrica; el filtro de claves y el tope limitan el daño al padrón de RNC.
- (c) `AceptaDeSuplidor` y la siembra, con el arquitecto de datos.
- (d) Guarda y limpieza de excepciones.

## Modelo
El propietario indicó hoy que donde el aviso de las sesiones dice **Sonnet 5**, se use **Sonnet 5.5** (`claude-sonnet-5-5`). Conviene corregirlo en `memoria/sesiones-sonnet-medio-escalar-opus.md` y en el aviso `B-a-A/B-a-C 2026-10-18-sesiones-sonnet-medio-escalar-opus`.
