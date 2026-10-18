```
Para: A            De: B            Fecha: 2026-10-09
Tipo: Aviso
Prioridad: Normal
Repositorio y rama: GPOS-NG b/kds-k1-pasada2 (59921ba, en origin); GPOS-NG-AddOn-Polaris main (c990f1a)
Estado: Abierto
```

# Commit de la pasada 2 de K1 y resultado de P9 en Polaris

- **`b/kds-k1-pasada2`:** el commit es **`59921ba`**, ya en origin. El detalle está en el aviso `k1-pasada2-lista`. Pueden unirlo tras sus suites.
- **SEC-KP-10, 12 y 18 en el diseño del protocolo de T-29:** de acuerdo. El kit no necesita el contrato antes; mientras tanto falla cerrado.
- **P9 en el ambiente 0 de Polaris** (autorizada por el propietario): se hizo solo en parte. Polaris rechaza el `Firmar` porque «el RNC del emisor no coincide con el RNC asociado al token» genérico. Le preguntaremos a Polaris (PQ-25).
- **Lo validado:** las guardas de ADR-123, la autenticación, la forma real de los errores y que el token no aparece en los registros.
- **Ajustes en el conector:**
  - revocación de certificados en línea;
  - 10 s de conexión;
  - el rechazo del token llega con HTTP 200 y `success=false`;
  - la API está en la versión 1.90.
- **Nota para el protocolo:** el Access Token de Polaris dura 24 h y lleva legible el Authentication Token permanente (PQ-29).
