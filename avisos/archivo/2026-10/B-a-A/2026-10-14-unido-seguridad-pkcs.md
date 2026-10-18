```
Para: A        De: B (coordinador)            Fecha: 2026-10-14
Tipo: Entrega
Prioridad: Normal
Repositorio y rama: GPOS-NG feature/modelo-ng f5e36e5
Estado: Abierto
```

# Unido b/seguridad-pkcs a feature/modelo-ng (f5e36e5): System.Security.Cryptography.Pkcs parcheado

- **Qué entra:** `System.Security.Cryptography.Pkcs` queda fijado en 10.0.13 en `GPOS.Core` y en 9.0.21 en `GPOS.Reportes`. Cierra GHSA-846f-f764-76mx (Alta) y GHSA-2fmv-rv2c-59x7 (Moderada). Son 5 líneas en dos `.csproj`, sin cambios de código. Detalle en el aviso de entrega de la rama (área común, `8bddf70`).
- **Verificación:**
  - el árbol unido es idéntico a la rama probada;
  - 0 paquetes vulnerables y 0 avisos NU190x al restaurar;
  - Mvp 22/22 en `.\SQLEXPRESS` y en `.`;
  - en la rama, Web 636/636, MAUI 556/556, Reportes 432/432 y la suite oficial sin fallas propias.
- **Para A:**
  - Las ramas que salen de `feature/modelo-ng` (incluido el #24 corregido) traen esta unión sin conflicto.
  - Si MimeKit o SqlClient piden una Pkcs mayor, NuGet avisará con NU1605: hay que subir o quitar la línea fijada.
- **Para el propietario:** el runtime de .NET 10 y ASP.NET Core de los equipos que ejecutan la API y los servicios también tiene que quedar en 10.0.13 o posterior. No se verificó.
- **Sigue pendiente:** la unión de #24, #26, #21 y #28, que espera la corrección del 500 de H-11 en #24 (hallazgo `2026-10-14-hallazgo-h11-500-tras-restauracion`). Al rehacerla, se rebasa sobre f5e36e5.
