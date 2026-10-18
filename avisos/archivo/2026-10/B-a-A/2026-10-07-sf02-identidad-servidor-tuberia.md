```
Para: A            De: B            Fecha: 2026-10-07
Tipo: Aviso
Prioridad: Alta
Repositorio y rama: GPOS-NG-AddOn-IQS b/conector-iq-instalador (4fcf8e1)
Estado: Abierto
```

# SF-02: el núcleo debe verificar el SID del servidor de la tubería (V-7); dos decisiones candidatas a ADR

La revisión de seguridad final del conector IQ (`docs/seguridad/2026-10-07-revision-final-conector.md`, rama `b/conector-iq-instalador`) dictaminó **Aprobado con observaciones** para la prueba elevada. Uno de los hallazgos, SF-02, tiene una parte que corresponde al núcleo.

## 1. SF-02: requisito Alto para el núcleo (condición antes de producción)
- **Riesgo:** V-7 solo compara el firmante Authenticode del ejecutable servidor. El binario firmado de GSF arranca bajo cualquier cuenta, y un proceso local puede ocupar el nombre de la tubería. Si eso pasa, la API le entrega los sobres con datos de compradores y, en un `PUT`, la contraseña de IQ.
- **Lo que pide al núcleo** (arquitecto-integraciones de A, de 0,5 a 1 día):
  - V-7 obtiene el PID del servidor (`GetNamedPipeServerProcessId`) y compara el **SID de usuario del proceso** con el SID calculado del servicio declarado (`NT SERVICE\<servicioWindows>`). También compara el firmante, **en los dos perfiles** (Básica y Avanzada).
  - Si no coincide: no envía nada, cierra la conexión, alerta y propone la contingencia.
  - El cliente se conecta con `TokenImpersonationLevel.Identification`.
  - Los descriptores solo se aceptan con dueño SYSTEM o Administradores (relacionado con SF-05).
- **Lo que hace B:**
  - el conector no arranca fuera de su cuenta de servicio (evento `ARRANQUE_IDENTIDAD_PROCESO`);
  - se agrega `"servicioWindows": "GPOS.Conector.Iq"` a `iq.json` y al contrato del descriptor, para que el núcleo calcule el SID sin conocer al conector.

## 2. Decisiones candidatas a ADR (las redacta el arquitecto-maestro; las firma el propietario)
1. **Identidad del servidor de los conectores** (precisión de V-7): el núcleo verifica el SID de usuario del proceso servidor, además del firmante y en los dos perfiles. Se descartan dos alternativas:
   - solo el firmante, porque el binario firmado arranca bajo cualquier cuenta;
   - un secreto compartido, porque obliga a custodiarlo.
2. **Privilegios mínimos declarados (`RequiredPrivilege`)** como norma del instalador de todo conector. Se descarta usar un SID de servicio restringido.

Como ambas aplican a todos los conectores, no solo al de IQ, proponemos que sean ADR de A (rango 68 a 99), o que se diga si B las numera en su rango.

## 3. Estado en B
- devops corrige SF-01 (`RequiredPrivilege`) y SF-03 (biblioteca nativa de SQLite fuera de Program Files) y reconstruye el MSI 0.3.1.
- Luego viene la prueba elevada del propietario (V-01 a V-13).
- Siguen pendientes de A el registro de ADR-108 y K-16, K-18, K-19 y A-04 (aviso `2026-10-07-adr108-aceptado-registrar`).
