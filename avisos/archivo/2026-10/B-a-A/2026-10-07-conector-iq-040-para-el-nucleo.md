```
Para: A            De: B            Fecha: 2026-10-07
Tipo: Entrega
Prioridad: Alta
Repositorio y rama: GPOS-NG-AddOn-IQS b/conector-iq-instalador (49f38b7)
Estado: Abierto
```

# Conector IQ 0.4.0: ADR-74, 75 y 76 y K-16, K-18 y K-19 en el conector; lo que le toca al núcleo y cinco preguntas

Responde a `avisos/A-a-B/2026-10-07-adr74-75-76-firmados.md` y a `2026-10-07-adr108-registrado-y-k16-k19.md`.

**Estado del conector**
- MSI 0.4.0, sin firma.
- 510 de 510 pruebas, en dos corridas seguidas.
- La verificación del auditor de 0.3.1 y 0.3.2 está unida (`49f38b7`): dictamen **Aprobado con observaciones** para la prueba elevada.
- Lo que sigue: la acción personalizada del MSI contra las uniones (0.4.1) y la prueba elevada del propietario.

## 1. Hecho en el conector
- **ADR-75, punto 5 (K-04 / SF-10):**
  - al arrancar, el conector concede a los SID de `Nucleo\IdentidadApi` solo `PROCESS_QUERY_LIMITED_INFORMATION` sobre su proceso y `TOKEN_QUERY` sobre su token;
  - eventos: `ACCESO_CONSULTA_CONCEDIDO`, `ACCESO_CONSULTA_SIN_IDENTIDAD_API` y `ARRANQUE_ACCESO_CONSULTA`;
  - la prueba con dos cuentas es el paso 7b de [OPS] 10 (script `sonda-pa751.ps1`).
- **ADR-76, punto 4:** autocomprobación de todos los privilegios del token; si hay alguno sobrante, deja `ARRANQUE_PRIVILEGIOS` y el servicio no arranca. La lista declarada es solo `SeChangeNotifyPrivilege`.
- **ADR-74, parte del conector:**
  - el resultado trae `llegoAlProveedor`;
  - las generaciones RECHAZADO y CONFLICTO tienen evidencia y admiten acuse; INVALIDO nunca tiene evidencia;
  - el contrato del sello está en la sección 19.4 del diseño.
- **K-18:**
  - el 400 de validación de IQ deja la generación en `CONFLICTO`: nunca se anula ni se reenvía de forma automática, con el evento `ECF_CONFLICTO` y la alarma `CONFLICTO_72H`;
  - «Reenviar corregido» usa el mismo e-NCF, después de dos consultas «no encontrado» separadas 60 s.
- **K-16:** tope de 3 e-NCF distintos para el rol R (409 `TOPE_EMISIONES_REEMPLAZO`).
- **K-19:** `ClaveComprobante.LargoMaximo = 42`, con el vector compartido en `GPOS.Conectores.Contratos` (`Vectores/vectores-clave-comprobante.json`), que incluye el `Uid` en mayúsculas que devuelve SQL Server.
- **Diario:** pasa al esquema 5.

## 2. Para el núcleo
- **ADR-75, puntos 1 a 4:**
  - comparar firmante, sujeto, emisor y EKU contra el manifiesto, en los dos perfiles;
  - comparar el SID del servidor con `GetNamedPipeServerProcessId`;
  - abrir la tubería con `Identification`;
  - validar los descriptores.
- **Manifiesto:**
  - `binarios` trae varias entradas;
  - `firmante` trae `emisor` y `eku`, o `"firmado": false` con `"firmante": null` cuando el MSI va sin firma;
  - el fragmento declara además `commit`, `arbolLimpio`, `runtimeNet` y `sqliteNativa`.
- **Carpetas compartidas (SF-05):** el MSI deja `%ProgramData%\GPOS NG` y `Conectores` con una ACL protegida, sin herencia de Users (control total para SYSTEM y Administradores; Authenticated Users solo lectura). Si el instalador del núcleo declara esas carpetas, **debe usar el mismo SDDL** ([OPS] 4.5); si no, el conector no arranca.
- **DDL de K-16 y K-19:** a cargo del arquitecto-datos de A. El contrato está en la sección 19 del diseño: las PK de `fiscal.*`, el privilegio de Especiales y `_LOG` son del núcleo.

## 3. Preguntas
- **P-04 (arquitecto-integraciones de A):** ¿se acepta que el «409 con el estado real» de K-18 llegue como resultado diferido de la generación y no como código del POST? Las dos consultas separadas 60 s no caben en la espera máxima de 8 s.
- **P-05 (A):** ¿se mueven las operaciones de acuse y contraste (`AcuseIntento`) a `GPOS.Conectores.Contratos`, como pide el punto 9 de ADR-74?
- **El 400 de IQ (pedido de A):**
  - la documentación OpenAPI de IQ, el mock y `GSF.SyncToIQS` tratan el 400 solo como `{error}`; el rechazo de la DGII llega como 200 con estado «Rechazado»;
  - el único caso conocido es «secuencia ya utilizada con el estatus X», que se resuelve consultando el estado real;
  - como defensa, un 400 que traiga un campo `estado` se consulta en lugar de quedar en `CONFLICTO`;
  - **no está confirmado con IQ:** el propietario lo agregará al cuestionario (P-02).
- **P-01 (especialista-contable):** un `CONFLICTO` anulado a mano, ¿va al 608 o a ANECF? Lo presenta B a su contador; si A ya tiene criterio, que lo diga.
