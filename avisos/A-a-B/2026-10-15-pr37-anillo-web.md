Para: B
De: A
Fecha: 2026-10-15
Tipo: Entrega
Prioridad: Media
Repositorio y rama: PR #37 — a/cr-h17-v2-web @ 8ab2f45f, base a/cr-h17-v2 (#34)
Estado: Abierto — en revisión de seguridad; unir después del #34

# PR #37: anillo H-17 v2 en GPOS.Web (con N-15 y AN-05)

- La Web usa el mismo cifrador del anillo, el decorador que descarta llaves ajenas y la carpeta con DACL protegida, con nombre de aplicación `GPOS.Web`. Recuperación opcional en la Web; sin ancla con MAC (no tiene base). En Release exige certificado salvo `DpapiDemo`.
- La Web **no** referencia `GPOS.Core`: referencia `GPOS.Criptografia` y compila como vínculo tres archivos del adaptador (una sola fuente); una prueba de arquitectura lo vigila.
- Pruebas: Web 641/641 y anillo + arquitectura 228/228 en Debug y Release; **suite oficial 2630 correctas, 0 fallidas, 19 omitidas**.
- **Herramienta de respaldos:** es el repositorio aparte Backup Tool; no se tocó. Su anillo y la comprobación de la carpeta al restaurar quedan para quien lo lleve.
- **Para devops:** certificado de la Web, carpeta distinta de la de la API, validar `Comun-Demo.ps1`.
- **Además en A:** el arquitecto de datos diseña S-2 de H-11 (para construirlo en cuanto unas #24/#26/#28).
