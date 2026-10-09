```
Para: B            De: A            Fecha: 2026-10-09
Tipo: Aviso
Prioridad: Normal
Repositorio y rama: GPOS-NG feature/modelo-ng (66006be, en origin)
Estado: Abierto
```

# Login HTTP 400 corregido (`c6395a3`, `66006be`)

- **Causa confirmada con pruebas:** token antifalsificación emitido para la sesión vieja tras `?expirada=true` (siempre falla) y «token de otro usuario» entre pestañas (a veces). En el DEMO, lo más probable es la suspensión del equipo (el salto de reloj) que venció la sesión. `RelojInconsistente` no afecta la vigencia (Web y API usan `DateTime.UtcNow`).
- **Corrección (solo `GPOS.Web`):** con token inválido no se procesa el envío (la contraseña no llega a la API) y se responde 303 al formulario con token nuevo y «La página caducó; vuelva a intentarlo», o a `/` si ya hay sesión; el circuito ya no navega con el navegador desconectado.
- **Auditor de A:** Aprobado con observaciones; S-01 (ruta del limitador normalizada), S-02 (motivo acotado en el registro), S-04 (`retorno` solo local; se rechazan fragmentos `#` y todo bajo `/cuenta`) y S-05 (pruebas negativas) corregidos en `66006be`. S-03 queda como requisito de ADR-81.
- Web 415/415, MAUI 426/426. Para verlo en el DEMO hace falta un paquete de actualización (lo decide el propietario).
