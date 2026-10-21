```
Para: B        De: A        Fecha: 2026-10-21
Tipo: Entrega (revisión de seguridad del ADR-93, #134; tarea 2 del encargo)
Prioridad: Media
Repositorio y rama: GPOS-NG-Equipos `traspasos/A/revision-seguridad-adr93-2026-10-21.md` (sobre `origin/b/adr93-tarjetas-foto` y `feature/modelo-ng` @ fc7f07f2)
Estado: Abierto
```

# ADR-93: Aprobado con observaciones

Solo lectura. Sin Críticos ni Altos **si S-01 a S-04 se toman como condiciones para construir E-2**. Si la subcarpeta del ADMIN queda como texto libre, pasa a **Rechazado** (riesgo Alto).

- **TB-03 (banco):** la subcarpeta del ADMIN no es texto libre: elige una base de la lista y el servidor arma `base\IdEmpresa`; nada toca disco o red antes de validar la lista (que la API no se autentique contra un servidor de red elegido por el ADMIN: S-01). Volver a marcar una carpeta ajena anula la marca HMAC: adoptarla es solo del SUPER (S-02). Carpetas del sistema rechazadas «dentro de» y «contiene a» (S-04). Enlaces comprobados sobre el archivo ya abierto, como `ComprobacionCarpetas.cs:99-129` (S-03). La bitácora de seguridad solo la ve el SUPER (`AdminEndpoints.cs:347-355`): hace falta una vista del ADMIN por empresa, registrar los intentos rechazados y exigir autenticación reciente para cambiar la raíz (S-06, S-07).
- **H-1 (correo):** causa en lista cerrada, sin el mensaje de la excepción (trae la ruta absoluta); mostrar un alias de la base, no un recorte de la ruta real (S-08). El SMTP admite enviar sin TLS (`EnviadorCorreo.cs:39`): Baja, el correo no lleva secretos.
- **Permisos de la foto y de la lista de ambiguos:** el ADR no fija la matriz; la propongo en el informe con prueba de 403 por ruta (S-10). El CSV debe neutralizar fórmulas reutilizando `ExportadorReporte.cs:199-212` (S-11). El proxy Web pierde `nosniff` y la CSP (`GPOS.Web/Program.cs:187-207`): la foto necesita su propia ruta (S-12). En la entrega 2, medios por huella acotados a la empresa del nodo (S-15).
- **TA-P08:** el filtro solo afecta a la tarjeta; `GET /api/inventario/existencias` y el kárdex ya entregan las existencias de todas las sucursales al usuario restringido (`InventarioEndpoints.cs:91-96`, `InventarioService.cs:723-735`) (S-16). La restricción no viaja en el token: léanla en el servidor como `ProveedorContexto.cs:90-99` de Reportes, y ante la duda devuelvan vacío, nunca «todos» (S-17).
- **Costo:** unos 3,2 dp (±50 %) sin S-16, casi todo dentro de las pruebas y guardas que E-2 ya presupuesta; USD 0.

## Preguntas para B (no reabren el ADR)
1. **PREGUNTA-1:** ¿quién puede dejar archivos a mano en el banco? Choca con la regla de permisos de carpetas de ADR-77.
2. **PREGUNTA-2:** en el ADR, TN-02 es integridad y espacio del nodo, no permisos de la foto; revisé ambas cosas. ¿A qué se refería el encargo?
3. **PREGUNTA-3 (antes de empezar E-1):** ¿TA-P08 es solo de presentación o de confidencialidad? Si es lo segundo, hay que filtrar también existencias, kárdex y la pestaña Almacenes (1 a 1,5 dp).
4. **PREGUNTA-4:** el propietario dijo «solo la central» ve el alcance global y el ADR lo traduce como «sin restricción»: confirmar.

Respuesta requerida: las cuatro preguntas (la 3 antes de E-1).
