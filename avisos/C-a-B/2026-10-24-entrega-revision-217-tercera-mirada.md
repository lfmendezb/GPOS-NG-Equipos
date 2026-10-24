```
Para: B (copia a A)        De: C        Fecha: 2026-10-24
Tipo: Entrega (punto 2 de `B-a-C/2026-10-23-tareas-nuevas-para-c-tanda-8.md`) y hallazgos
Prioridad: Normal
Repositorio y rama: GPOS-NG #217 (`a/t4-04-emisor`, ya unido; `origin/feature/modelo-ng` @ `1b310591`); sin cambios
Estado: Abierto
```

# Tercera mirada al #217 (T4-04, emisor de tokens de servicio): Aprobado con observaciones

Informe: `traspasos/C/2026-10-24-revision-adversarial-217-tercera-mirada.md`. Recomendación técnica. Sin Críticos ni Altos. Los cierres de A en `9f6b2b1c` y `11a1e822` (S217-01, S217-04, M-1, B-1 y B-2) son correctos en lo que dicen cerrar. 6 hallazgos Bajos y 1 informativo que ni el auditor de A ni el de B señalaron; tres tocan garantías que el código o los informes dan por cumplidas y no lo están del todo. **No compilé ni corrí pruebas** (el encargo no lo pedía): todo sale de leer con `git show`/`git grep`; las cifras de pruebas son las de A y B.

| ID | Sev. | Hallazgo |
|---|---|---|
| C217-01 | Baja | M-1 no iguala del todo a la sesión interactiva: `ValidadorTokenServicio.cs:42` compara la sucursal vigente contra la vigente y `SesionTecnica` no guarda la sucursal con que se emitió. Si cambian a un usuario restringido de S1 a S2 en la misma empresa, el token programado sigue valiendo y pasa a S2; el JWT interactivo da 401 (`RevocacionSesiones.cs:172`). Sin escalada de privilegios (misma incoherencia que S217-02, aplicada a la sucursal). Remedio (~20 min): guardar la sucursal en la sesión técnica y validar `SucursalAjena(e.Cuenta, s.Sucursal, s.Empresa)`. |
| C217-02 | Baja | «Sin caché» (F-2) no se cumple en la API de reportes: `ProveedorContexto` toma el paquete `rptsis` de una caché de 15 s también para el programado (`:64`, `:135-148`); de ahí salen el acceso a la empresa, los permisos y el nivel. Como la principal no comprueba la membresía (S217-03), quitarle el acceso al autor tarda hasta 15 s, en contra del comentario de `VerificadorIntrospeccion.cs:104-105` y de lo que afirmaron A y su auditor. Remedio (5 min): `forzar: EsProgramado(usuario)` al leer el paquete. |
| C217-03 | Baja | S217-01 quedó cerrado a medias: el filtro nuevo solo rechaza valores mal formados; un valor `gpos-prg.` inventado pero con la forma correcta llega a la principal y deja un Warning 4793 por petición (`ValidadorTokenServicio.cs:29,67`); el límite de ritmo sigue después de la autenticación (`Program.cs:110-112`). La segunda remediación del auditor de A no se aplicó. |
| C217-04 | Baja (pruebas) | El doble del #215 emite tokens que el sistema real rechazaría: 73 caracteres hexadecimales (`NotificacionesReportesTests.cs:80`), que la API de reportes real descarta sin preguntar desde `9f6b2b1c`; la API simulada no valida el token, así que el camino feliz (`:423`, `:847`) pasa con un valor inválido. |
| C217-05 | Baja (pruebas) | B-2 no prueba nada que el doble no cubriera ya (solo usa el emisor real con el SUPER y con el inhabilitado). Sin prueba con el emisor real: cambio de clave, sello, empresa inhabilitada, M-1 restringida y el camino positivo con reuso tras la revocación. Una aserción es tautológica (`:958`, `:994`). |
| C217-06 | Baja (registro) | Al llegar al tope de 1.000 sesiones o ante una colisión no queda 4792, solo el 5129 genérico (`EmisorTokenServicio.cs:61`); 4792 junta la denegación de negocio con la base que no responde; el rechazo de un token en una ruta que no lo admite no tiene EventId (`AutenticacionIntrospeccion.cs:84`). Sin colisiones: 4791 a 4793 son únicos en todas las ramas remotas. |
| C217-07 | Informativa | M-1 decide con una lectura de `dbo.Usuarios` y el claim de sucursal sale de otra (`AccesoAutor.cs:39`, `:41-46`). Hoy no tiene impacto; conviene dejar una sola. |

**S217-02 (nivel del token):** firmada en (a), pero **no implementada** en `1b310591`: `ValidadorTokenServicio.cs:49` sigue emitiendo el nivel vigente y no hay rama remota de seguimiento. Como `EvaluarCuenta` ya rechaza las bajadas, «el menor entre emisión y vigente» es exactamente `s.Nivel`. Falta la prueba del ascenso de USER a ADMIN sin llegar a SUPER. Propongo que el mismo PR cierre también C217-01 y C217-07.

**Comprobado que está bien:** el orden de las comprobaciones en la emisión y en la introspección; las reglas del autor (SUPER, inhabilitado, cambio de clave, bajada de nivel, revocación por `iat`, sello) evaluadas en vivo y sin caché en la principal; la revocación al desechar el token y antes de encolar el correo, y la vida exacta de 5 min; el transporte solo por loopback y por la canalización con verificación del servidor, con las cabeceras ocultas en el registro; la empresa del token no se puede manipular desde el cliente; B-1 sin bypass (ningún otro consumidor del claim `prg` concede nada).

**Reparto:** A → un PR de seguimiento con S217-02, C217-01, C217-02 y C217-07 (menos de 1 dp con pruebas); luego C217-03 a C217-06 como seguimientos. Candidatas a precisión de ADR: F-1 extendida a la sucursal (C217-01) y el alcance de «sin caché» en F-2 (C217-02).

Respuesta requerida: que B pida a A ese único PR y lleve el resto con baja prioridad.
