```
Para: A        De: B        Fecha: 2026-10-20
Tipo: Aviso (firma del propietario: F-1)
Prioridad: Media
Repositorio y rama: GPOS-NG-Equipos `traspasos/B/2026-10-20-respuestas-b-a-los-planos-de-a.md` (sección de F-1)
Estado: Abierto
```

# F-1 firmada por el propietario: opción B

El propietario respondió el 2026-10-20 en el chat: «De F-1 sobre los instaladores ya había respondido que B, mantendremos los instaladores en .net472 hasta cumplir con el cronograma propuesto de modo que no nos atrasemos». Se toma como firma de **F-1 con la opción B**: la excepción a `CLAUDE.md:24` para el proyecto de la acción previa `instalador/Comun/GPOS.Instalador.Acciones` en `net472`, fuera de `GPOS-NG.slnx`, con WiX y los MSI existentes sin cambios de tecnología.

## Qué desbloquea
- **O-1 y O-3** pueden empezar (con las condiciones HB-01 y H-4 del documento de B).
- **PR-1b** de ADR-90 (`GPOS.Comun.Servidor`) y los `.wixproj` de Api, Web y bundle, tal como nombra F-1 en el documento de B (cinco proyectos). Si el propietario quería limitar F-1 a la acción previa, lo corrige y B avisa.

## Condiciones
- **`net472` es temporal:** hasta cumplir el cronograma. Cuándo se revisa (tras la entrega 1, tras la 2 o tras el corte de diciembre) lo precisa el propietario; B avisa.
- **Regla nueva del propietario (2026-10-20):** ninguna tecnología se elige ni se cambia sin consultarle. .NET 10 es su decisión de base; cualquier otro runtime, framework, herramienta de empaquetado o versión mayor exige su aprobación antes. A no propone ni adopta tecnología nueva sin que B la lleve a él.
- No se reabre la comparación con otros instaladores; WiX 5.0.2 se mantiene (la cuota de WiX 6/7 queda como pregunta de licencia de B).

## Sigue sin firmar
F-5 (adelantar PR-4 y N-1 a la ventana 10-28 a 11-06) y F-6 (`Api:Url` del registro; `tls` después de los MSI). A no toca el `Program.cs` de la API hasta F-5 y N-1.
