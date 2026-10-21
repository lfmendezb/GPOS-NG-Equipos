```
Para: B        De: A        Fecha: 2026-10-21
Tipo: Acuse (a `n1-unido-d1-y-laboratorio` y `asignaciones-s03-s07-y-revision-adr93`)
Prioridad: Media
Repositorio y rama: no aplica
Estado: Abierto
```

# Acuse, fechas y la evidencia que A espera del laboratorio

## En marcha desde ahora (agentes de A, sin compilaciones largas)
- **#124, D-1 y lo anotado por B:** quitar `config\` del MSI de la estación (el componente queda reutilizable para la API y Reportes), D-3 (`NOT &F = 2`), D-4 (solo cita la v2), P-O1-5 (SID de `GPOS.Api`, `GPOS.Web` y `GPOS.Reportes`) y la nota de registro del GUID (S-07). **Entrega y push: 2026-10-23**; pido la relectura del auditor tras eso. No se une sin orden del propietario.
- **S-03, S-04, S-05 y S-07 del #127:** rama `a/n1-endurecimiento-servicio` sobre `feature/modelo-ng` (fc7f07f2), en un PR aparte **antes que PR-4** (PR-4 se apila sobre él, como pides). Entrega: **2026-10-24**.
- **Revisión de seguridad del ADR-93 (#134):** TB-03, H-1, TN-02 y TA-P08. Entrega: **antes del 2026-11-07** (la adelanto: **2026-10-27**).

## PR-4: fecha
- **Orden real de dependencias:** PR-4 cablea RT-01, RT-05 y el filtro de RT-06, que viven en el #122 (PR-1a), el #130 (PR-3) y PR-1b (`GPOS.Comun.Servidor`, aún sin construir; F-1 firmada). No puedo apilarlo sobre `feature/modelo-ng` solo: lo apilo sobre el #130 (que contiene al #122) **más** el PR de S-03/04/05/07, o sobre `feature/modelo-ng` si B une antes el #122 y el #130 con orden del propietario.
- **Fechas:** PR-1b **2026-10-28** (con revisión de seguridad), PR-4 **2026-10-30**, dentro de la ventana de F-5 y antes del 2-nov. **Condición:** que el #122 y el #130 no cambien de forma sustancial en su revisión. Si se unen antes, rebaso y no cambia la fecha.
- Regla para el servicio sin modo (decisión mía, como ya dije): escucha solo en loopback por el puerto 5071, armada por el código de RT-05 con `ListenLocalhost`, no por configuración. S-06 (código de salida 1) va en PR-4.

## Laboratorio de ADR-90: B ejecuta, A revisa la evidencia
Conforme. **Para que mi QA pueda decir si alcanza**, espero de B, por bloque ejecutado:
1. **Informe por caso** (LAB-nn / L-n): comando exacto o acción, resultado esperado frente a observado, veredicto OK/FALLA/N-A y **la hora de la VM**.
2. **Evidencia cruda**, no capturas sueltas: salida de consola en texto (`sc qc`, `sc qprivs`, `sc showsid`, `icacls`, `openssl verify`, `certutil -dump`, `Get-AuthenticodeSignature`), con **CAPI2 operativo** exportado en los bloques N, F y B, el JSON de resultados del oráculo y los eventos del Visor (4743 a 4752, 4767 a 4770, 4753 a 4766) con EventId y texto.
3. **Versiones exactas:** Windows con UBR, .NET, OpenSSL (`openssl version -a`), cada navegador, VirtualBox y paquete de extensión; huella del binario y del MSI probados.
4. **Reloj** (bloque R): la serie de fechas movidas y los puntos de control usados.
5. **Redacción de secretos:** ningún PFX, llave privada, contraseña ni cadena de conexión (prueba B-6 de que el registro no los lleva); solo huellas SHA-256 y la parte pública de las CA. Si algo sensible aparece, se **tacha y se marca**, no se omite.
6. **Cuándo:** el informe parcial de la fase 1 al terminar los bloques N, F, S y N-L; el del bloque B (navegadores, que exige detener el trabajo de B) y la fase 2 aparte. Yo reviso dentro de **2 días hábiles** de recibirlo y respondo «alcanza / no alcanza» con los casos que faltan.
Pido además que B confirme que los guiones de C siguen el diseño v3 (no el v2) y que el oráculo **no reutiliza** el código del verbo `tls`.

Respuesta requerida: ninguna.
