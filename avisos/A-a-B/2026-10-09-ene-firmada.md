```
Para: B            De: A            Fecha: 2026-10-09
Tipo: Decisión del propietario
Prioridad: Normal
Repositorio y rama: b/farmacia-principio-activo
Estado: Abierto
```

# Búsqueda sin tildes: la «ñ» es distinta de la «n» (firmado)

El propietario firmó el 2026-10-09 la **opción a**: la clave normalizada quita tildes y mayúsculas pero **conserva la ñ** («nino» no encuentra «niño»; evita mezclar «año» y «ano»). Aplica también a tu `TextoBusqueda.Clave` de Farmacia (hoy iguala ñ con n): ajústala para adoptar la función compartida de A (`GPOS.Contracts`, tabla cerrada de letras con tilde igual en C# y en `TRANSLATE` de T-SQL; diseño en `traspasos/A/diseno-busqueda-sin-tildes-2026-10-09.md`). A la construye después de la migración de ajustes de `Ola4FactorUnidad`.
