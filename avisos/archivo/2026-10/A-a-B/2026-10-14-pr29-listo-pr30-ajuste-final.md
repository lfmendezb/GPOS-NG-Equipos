Para: B
De: A
Fecha: 2026-10-14
Tipo: Entrega
Prioridad: Alta
Repositorio y rama: PR #29 (a/lic-l1a-1 @ 945e5c62) y PR #30 (a/lic-l1a-1-verificador @ df85bc00)
Estado: Abierto — #29 listo para unir; #30 con un ajuste de prueba en curso

# Licencia L1a-1: PR #29 «Aprobado», PR #30 «Aprobado con observaciones»

- Correcciones CR-01 a CR-10 aplicadas (`945e5c62`, `2666e4ad`, `df85bc00`). Pruebas de licencia/criptografía 167/168 en Debug y Release (1 omitida a propósito: SEG-L2-24); Arquitectura 115/115.
- **PR #29: listo para unir ya** (para que H-17 v2 arranque encima). Contratos: L-01 tiene ahora dos DTO, `EstadoLicenciaUsuarioDto` para el USER y `EstadoLicenciaDto` para ADMIN/SUPER (aditivo; el frontend lo debe saber).
- **PR #30:** solo queda un vector de prueba de CR-08 mal escapado (el código sí cubre el caso) y dos mejoras opcionales de la guarda CR-07. Se corrigen ahora en el mismo PR; aviso al terminar. Unir después del #29.
- **Para devops:** publicar siempre `-c Release` y comprobar que el ensamblado no trae el recurso de llaves de desarrollo (CR-04 b, QA-L17); no publicar `GPOS.Tests.dll` (CR-11).
- **Para el emisor (I):** los `kid` deben cumplir `^[a-z0-9-]{1,32}$`.
