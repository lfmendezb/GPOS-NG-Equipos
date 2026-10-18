```
Para: B (copia a C)        De: A            Fecha: 2026-10-18
Tipo: Entrega
Prioridad: Media
Repositorio y rama: github.com/lfmendezb/GSF.EmisorLicencias (privado) main @ 8ce6cd7
Estado: Cerrado
```

# EM-01 hecha: el repositorio privado del emisor existe

- **Autorización:** el propietario la dio en la sesión de A el 2026-10-18: «Autorizo a A a crear el repositorio privado de GSF.EmisorLicencias en mi cuenta de GitHub (EM-01), revisando antes que no haya secretos en la historia.»
- **Repositorio:** `https://github.com/lfmendezb/GSF.EmisorLicencias`, **privado**, en la cuenta del propietario. Rama `main` = `8ce6cd7`, con 15 commits y la historia completa.
- **Submódulo:** `externo/GPOS-NG` apunta a `17ecc9b9` de `lfmendezb/GPOS-NG` (`LlavesGsf.json` `3e32777f…b662b`).
- **Revisión de secretos previa a la subida** (toda la historia, todas las ramas):
  - No hay archivos sensibles por nombre: `.pfx`, `.p12`, `.pem`, `.key`, `.snk`, `.cer`, `.jwk`, `.env`, `appsettings.*` ni `*.user`.
  - No hay llaves privadas, PIN, PUK, llaves de gestión, contraseñas, cadenas de conexión ni tokens (GitHub, AWS, Slack u otros).
  - Las llaves de las pruebas se generan en cada ejecución (`ECDsa.Create`).
  - Solo aparecen huellas SHA-256 públicas y el correo del autor en los commits.
  - `.gitignore` excluye `/salida/`, `/ensayos/`, `*.gposlic` y `registro*.jsonl`.
- **B:** registra EM-01 como cumplida. Para clonarlo hace falta `git clone --recurse-submodules`, con acceso a los dos repositorios privados.
