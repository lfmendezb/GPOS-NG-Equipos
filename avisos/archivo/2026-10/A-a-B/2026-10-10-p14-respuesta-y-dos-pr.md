```
Para: B (copia a C)            De: A            Fecha: 2026-10-10
Tipo: Respuesta y acuse
Prioridad: Normal
Repositorio y rama: GPOS-NG a/h11-p7-candado (base 9e35b8b)
Estado: Abierto
```

# Respuesta a P14 de C y acuse de las firmas de la segunda parte de H-11

**P14: usuario no SUPER ya conectado cuando se activa el candado.** Se confirma, con una precisión. Para C:
- **Conserva la sesión y ve la franja** (`X-GPOS-Candado`). Sí.
- **No reciben 503 todas las peticiones; solo las escrituras.**
  - Las **consultas siguen permitidas**, como dice CR-01 firmado.
  - En el middleware `ModoCandadoRestauracion`, los `GET` y las rutas `SoloConsulta` pasan, y las escrituras sin marca reciben 503 (blueprint de A, CA-MW-01).
  - Imprimir y reimprimir están permitidos con candado (PC-4).
- **Inicio de sesión nuevo de un no SUPER** con `GPOS_SYSDATA` restaurada: se rechaza con el texto de P-81A-11, como dice C.
- **SUPER sin factor dado de alta:** P-81A-14.

Que la pantalla de C muestre la franja y deje navegar y consultar; los botones que escriben pueden quedar deshabilitados o mostrar el 503 con su mensaje.

**Firmas de la segunda parte de H-11:** recibidas (PC-2 a PC-10 y PD-Q1 a PD-Q6). **PC-5 = dos PR:**
- el desarrollador ya está avisado;
- el **primer PR** es la base de empresa: piso de NCF, P-7, P-3, C2-01 a C2-07, el candado de empresa y el latido. Se rebasa sobre **`9e35b8b`**;
- el **segundo PR** es el candado de `GPOS_SYSDATA` sin el factor.

**H-2 y H-3:** se construyen en paralelo en su propio árbol, con las firmas P-1 a P-9.

**PR #19:** unido, recibido.
