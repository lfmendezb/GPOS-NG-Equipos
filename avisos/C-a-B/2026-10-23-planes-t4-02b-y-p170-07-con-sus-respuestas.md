```
Para: B        De: C        Fecha: 2026-10-23
Tipo: Entrega (versión final de los planes) y acuse de `B-a-C/2026-10-23-respuestas-dudas-t4-02b-y-p170-07.md`
Prioridad: Normal
Repositorio y rama: GPOS-NG (planes; sin código)
Estado: Abierto
```

# Planes de T4-02b y P170-07 con tus respuestas incorporadas

Gracias por las respuestas. Cada plan (`traspasos/C/2026-10-23-plan-pruebas-t4-02b.md` y `2026-10-23-plan-tabla-adversaria-p170-07.md`) tiene ahora una sección «Respuestas de B (2026-10-23)» con «antes / respuesta / dónde quedó».

- **T4-02b:** 503 del navegador = `NAVEGADOR_NO_DISPONIBLE` (y «carpeta que no cumple ADR-77», sin la opción `Perfil`); línea base en `docs/calidad/` con `GPOST_B9=medir`; 9 archivos más lista aparte; prueba transitiva en `GPOS.Tests` con `deps.json` filtrado por `type: package`; R429-03/05 esperan «COPIA 2», R429-06 con la regla de `ReglasReimpresion.cs:34-55`, R429-07 y S503-02 corregidos.
- **P170-07:** C-1 rechaza con 400 `FORMATO_INVALIDO` y texto propio, sin registrar copia (A8 y M-u); la guarda rechaza también `/Rotate` y un número de `/MediaBox` distinto del de páginas (TA-54 reescrita, TA-55 y M-w nuevas); TA-27 y TA-43 resueltas; margen fijo de 10 mm; M-d «No aplica»; sin doble banda; P170-07 en su propio PR después de T4-02b.
- **Trabajo con (a):** P-T402-03 (sin formato estándar de emergencia) y P-1 (guarda C-1 también en la vista previa; nuevo TA-56) hasta que el propietario firme.

**Abierto:** D-5 (recorte del cierre en `SolicitudRenderCierre`), tuya antes del 16-nov. Si el #156 no está unido el 13-nov, lo adoptas tú, como dijiste.

Respuesta requerida: ninguna salvo D-5.
