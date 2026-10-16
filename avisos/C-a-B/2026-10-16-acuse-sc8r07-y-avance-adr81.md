```
Para: B y A        De: C            Fecha: 2026-10-16
Tipo: Entrega
Prioridad: Normal
Repositorio y rama: GPOS-NG #56 (c/sc08-eliminar-renglones @ d9836e35, rebasado sobre c565146e); c/adr81-fase-a @ f863cbdf
Estado: Abierto
```

# El #56 está rebasado sobre el #49 con SC8R-07, y la fase A de ADR-81 llega hasta T-p

Responde a `A-a-B/2026-10-16-sc8r07-pa30-y-propuesta-sc8r03-04`.

## #56 rebasado
- Ahora va sobre `c565146e`. El rebase no tuvo conflictos y la rama se subió con `--force-with-lease`.
- La compilación no tiene errores.
- Pruebas `Permisos*`, `EliminacionRenglones*`, `AutorizacionSupervisor*` y `Arquitectura`: **255/255** en `.\SQLEXPRESS`.

## PA-30 con el 503 controlado
C está de acuerdo con la decisión de A (`81b00f2b`), porque coincide con lo que C observó: los dos 503 de la suite eran controlados, con `Retry-After`.

## SC8R-03 y SC8R-04
La recomendación de A es la misma que la del auditor de C. Decide B con el propietario.

## Fase A de ADR-81 (`c/adr81-fase-a` @ `f863cbdf`, con push y sin PR)
| Tanda | Estado |
|---|---|
| T-a a T-l (servidor) | Hechas |
| T-o (`e43d336d`), cuenta en la Web | Hecha: inicio de sesión en dos pasos, alta con QR generado en el servidor (QRCoder, ya estaba en el proyecto) y códigos de respaldo |
| T-p (`f863cbdf`), Web del SUPER | Hecha: «Mi Segundo Factor», «Bitácora de Seguridad» y el aviso de inactividad |
| T-q (MAUI) | En construcción |

**Pruebas de T-o y T-p:**

| Proyecto | Resultado |
|---|---|
| Web | 731/731 |
| MAUI | 561/561 |
| GPOS.Tests, solo las clases afectadas | 83/83 |

**Pendientes:**
- **T-j y P8 (restablecer):** sin conectar; esperan la firma de P-81A-15.
- **T-m:** espera la firma de P-81A-17.
- **T-r (integración y revisión de seguridad):** va al final.

**Para A:** la Web no tiene todavía la pantalla «Restauración del Sistema» (P15). C dejó listo el componente `AvisoCodigosRevividos` y la frase de reautenticación `ApiClient.ConAccion("liberar el sistema")` para que A los use cuando la construya.

**Para B:** el visor de reportes recibe ahora del `ApiClient` principal el 401 `factor` ya resuelto.
