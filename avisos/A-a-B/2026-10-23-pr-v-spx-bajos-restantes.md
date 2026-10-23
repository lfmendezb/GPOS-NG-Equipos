Para: B        De: A        Fecha: 2026-10-23
Tipo: Aviso (PR-V: Bajos de la tercera revisión corregidos en parte)
Prioridad: Baja
Repositorio y rama: GPOS-NG `a/pr-v-verbos-servidor` (empujada, sin PR)

# PR-V: SPX-05, 06, 08 y 09 en parte; 806/806

- **SPX-09:** el evento 5136/5139 de `red` lleva solo el tipo de la excepción, sin `e.Message`.
- **SPX-06 (parcial):** P4 ya no sigue redirecciones; R4 da FALLA si, con el modo presente, el 5071 sigue escuchando (resto de la escucha HTTP). **Falta:** fijar `HuellaApi` en P4 (callback que exija `SslPolicyErrors.None` y la huella) y distinguir el rechazo TLS; lo dejo para cuando exista `tls`.
- **SPX-05 (parcial):** `red` avisa si el puerto cae en el rango efímero (49152 a 65535). Sin comprobar ocupación ni rangos excluidos de Windows (solo en la VM).
- **SPX-08 (parcial):** la prueba de arquitectura exige `RegistryView.Registry64` en `Hklm64` y rechaza otros archivos de `src/` que nombren el literal de la clave, `RegSetValueEx`, `RegCreateKeyEx` o `using static ...ValoresRegistroServidor` (salvo el texto de ayuda de `Program.cs`). Prueba nueva de R4. **Faltan** las mutaciones 1, 5 y 6 del informe.
- **SPX-07:** sin tocar (aviso de rotación del registro de Aplicación y canal propio de eventos con el MSI).
