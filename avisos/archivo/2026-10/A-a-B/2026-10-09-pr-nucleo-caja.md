```
Para: B            De: A            Fecha: 2026-10-09
Tipo: Aviso (PR listo, encargo de apoyo, tarea 3)
Prioridad: Normal
Repositorio y rama: GPOS-NG a/nucleo-caja (1a2fb36) sobre feature/modelo-ng 59921ba
Estado: Abierto
```

# PR listo: núcleo de caja (reimpresión y redondeo del vuelto)

- **PR:** https://github.com/lfmendezb/GPOS-NG/pull/8. Commits `fa6c45b`, `97ad6a4`, `fb02f0f`, `cf9e5ab`, `1a2fb36`.
- **Migraciones nuevas:** `20261009233424_NucleoCajaReimpresion` y `20261010000121_NucleoCajaRedondeoVuelto`, con el script de empresa regenerado. **Ojo al unir:** si `feature/modelo-ng` recibe otra migración antes, hay que reordenar y regenerar el script.
- **Para tus ventanas por vertical:** `DialogoAutorizacionSupervisor` admite ahora `TextoBoton`, `Encabezado` y `MotivosRapidos`. Para imprimir, usar `ImpresionDocumentos`, que es el camino único: `gpos.imprimirDirecto` ya no existe y se sustituye por `gpos.entregarPdf`. `ConfigPosDto.RedondeoVuelto` y `RedondeoVuelto.Entregado` están en `GPOS.Contracts`.
- **Pendiente:** el supervisor dentro del diálogo de correo, porque necesita `Autorizacion` en `EnvioDocumentoDto` y eso es un cambio de contrato; la RI automática de VF-13 llega con T-29; los puntos 1 y 2 de ADR-81 en `AutorizadorSupervisor`.
- **Pruebas en A:** Web 459/459, MAUI 432/432, y las filtradas de GPOS.Tests (48 + 160 + 2), todas pasan. La suite completa la corres tú. La revisión de seguridad de A está en curso y su dictamen irá en el PR.
