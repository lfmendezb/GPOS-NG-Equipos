Para: B (copia para C)        De: A        Fecha: 2026-10-23
Tipo: Aviso (condición previa de `a/t4-04-emisor`: P175-02 con el emisor real)
Prioridad: Media
Estado: Abierto

- **Hecho:** las dos pruebas de P175-02 (1) del #197 (`Una_regla_guardada_por_el_SUPER…` y `Una_regla_de_un_autor_inhabilitado…`) pasan con el `EmisorTokenServicio` REAL de `a/t4-04-emisor` (1927608d) en lugar de la reproducción de la prueba (2/2). Mutación: sin la línea `EsSuper` de `ReglasAccesoAutor.MotivoDenegacion`, la del SUPER falla (se envía el correo). Los textos de denegación coinciden.
- **Cómo:** árbol desechable (c/p175-pruebas `b4b80c3a` + a/t4-04-emisor), sin empujar; el cambio en la prueba está en `traspasos/A/p175-02-emisor-real-prueba.patch` (solo para cuando se quiera dejarlo como prueba permanente: `UsarEmisorReal()` justo antes de `ProgramadoAsync`, porque `ReglaAsync` borra `Tokens.Delegado`).
- **Hallazgo:** `a/t4-04-emisor` **choca con `feature/modelo-ng`/#197 en dos archivos**: `RevocacionSesiones.cs` (A extrajo `EvaluarCuenta`; la rama trae `SucursalAjena`/TA-P08) y `ProveedorContexto.cs` (`EsProgramado` frente a `Restringe`). Resolución probada: conservar ambos; en `Evaluar`, tras `EvaluarCuenta`, `if (SucursalAjena(cuenta!, token.Sucursal, token.Empresa)) return ValorCredenciales;` antes de `Validar`. Compila; las dos pruebas pasan. La haré en el rebase al abrir el PR.
- **Nota para T4-07-02:** el token de servicio NO pasa por `SucursalAjena` (solo la sesión interactiva), así que una cuenta restringida sin sucursal podría ejecutar programados; a tratar con la condición del #202.

Respuesta requerida: ninguna. Falta la orden del propietario para abrir el PR del emisor.
