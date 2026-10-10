```
Para: B            De: A            Fecha: 2026-10-09
Tipo: Aviso de avance y una precisión para firma
Prioridad: Normal
Repositorio y rama: GPOS-NG a/r1-r3 (44212b0, desde a/d-mvp-01)
Estado: Abierto
```

# R-1 y R-3: construidos; la seguridad pide ajustes; una precisión de CS-8 para el propietario

**Lo construido** (`a2bde4d`..`44212b0`):
- **R-1 (CS-7):** `POST /api/admin/usuarios` con `ClaveNueva` sobre la propia cuenta responde 400 `CLAVE_PROPIA_EN_ADMINISTRACION`. Web y MAUI deshabilitan el campo.
- **R-3 (CS-8):** inhabilitar o bajar de nivel revoca las sesiones. Además, en cada petición se comprueba la habilitación y que el nivel del token no supere al de la cuenta, en la misma lectura con caché de 15 s (CS-3), con 401 `cuenta-inhabilitada` o `credenciales`.

**Pruebas en A:** filtradas 219/221; las 2 que fallan ya fallaban en `f206153` (D-MVP-02 y VERSION_ESQUEMA). Web 457/457 y MAUI 434/434.

**Seguridad de A: «Aprobado con observaciones».**
- **H-1 (Media):** un código de usuario escrito de otra forma (caracteres de ancho completo) evita R-1, porque la comparación se hace en .NET y no con la cuenta resuelta por la base. **Se corrige antes del PR.**
- **H-2, H-3 y H-5 (Baja):** una carrera en la caché, un código sin resolver en `cerrar-sesiones` y pruebas de la ventana de 15 s. También en curso.

**Para el propietario, por tu conducto (H-4, Baja): precisión de CS-8.** CS-8 firmó que bajar de nivel renueva el sello **sin cerrar la sesión**. Como aún no existe el sello, la construcción actual **cierra la sesión** al bajar de nivel, y el auditor confirma que es más estricto y no abre ningún camino. Propuesta: firmarlo como precisión temporal de CS-8 («hasta que exista el sello, bajar de nivel cierra la sesión»). Con CS-1/CS-4 se alinea con lo firmado.

**Para QA (tuyo):** `EsquemaPendienteAccesoTests` falla de forma intermitente bajo carga (el pool de SqlClient da «Cannot open database GPOS_TEST_NUE_…» en `POST /empresas/NUEVA/esquema`). No viene de este cambio.

**PR:** lo abro cuando estén las correcciones y unas el #8 y el #10 (rebaso `a/r1-r3` sobre `feature/modelo-ng`).
