```
Para: B (copia a A)        De: C        Fecha: 2026-10-24
Tipo: Entrega (tanda 6 punto 1 y tanda 8 punto 4) y hallazgos
Prioridad: Alta (SF-01 y SF-03 conviene cerrarlos antes de que A cierre el orden de `FaseEsquema`, 5-nov)
Repositorio y rama: GPOS-NG [#228](https://github.com/lfmendezb/GPOS-NG/pull/228) (`b/f1-anillo` @ `e1c6f516`); sin cambios al PR
Estado: Abierto
```

# Revisión adversarial de F1 (el anillo del servicio, DM-07): Rechazado mientras SF-01 (Alta) siga abierta

Informe: `traspasos/C/2026-10-24-revision-adversarial-f1-anillo-pr228.md`; las 11 pruebas en `...-pruebas.cs.txt`. Recomendación técnica. El arreglo de SF-01 cuesta ~0,1 dp y no cambia la arquitectura; con SF-01 cerrada, o con el residuo aceptado por escrito por el propietario, y con SF-03 asignada a A antes del 5-nov, pasa a **Aprobado con observaciones**. No toqué el PR ni lo comenté.

**Lo que corrí.** Subconjunto del anillo (`Categoria=Anillo`, arquitectura del anillo, `EventIdUnicos`, `OrdenProgramaApi`, `ArchivoInstalacion`) más mis 11 pruebas contra SQL Server (`GPOST_TEST_SERVER=.`): **412 de 412 correctas**. Mutaciones: 31, una a la vez y restauradas con `git checkout`: **24 muertas y 7 sobreviven**. **No corrí** todo lo que exige administrador (llave CNG de la máquina, `LocalMachine\My`, `icacls`, servicios): la consola no está elevada; eso es W-AN-01 a 05 en la VM, que corres tú.

| ID | Sev. | Hallazgo |
|---|---|---|
| **SF-01** | **Alta** | SA-01 quedó cerrada solo en `--preparar` y `--anclar`. `anillo --cambiar-recuperacion` y `anillo --migrar` anclan el `.cer` configurado sin pedir la huella dictada (`MantenimientoAnillo.cs:147-148, 214, 229`). Además, con el archivo del anillo no hay un camino soportado para entregar el `.cer` nuevo: `--preparar` devuelve 4 y quedaría editar `config` a mano. SF01a y SF01b: el ancla queda con la huella ajena y `Cumple = true`. Remedio: `--huella-recuperacion` obligatoria en los dos verbos y `--cambiar-recuperacion --recuperacion <cer>` que escriba el `.cer` de forma atómica. |
| SF-02 | Media | `sistema` sin `--cuentas-iniciales` ni `--confirmar-sellado` escribe `Licencia.InstalacionId` (`ComandoSistema.cs:93`) y G-1 no cubre ese caso (`GuardasAnillo.cs:31`). Con el anillo de DPAPI del técnico, la fila queda escrita y el servicio ya no la verifica ni la reemplaza (prueba SF02). |
| SF-03 | Media (funcional) | El orden de PR-D2 del blueprint (3.3) pone `sistema --login-api` antes de `--anclar`, que no puede ir antes porque `sistema` es quien crea `GPOS_SYSDATA`. En una instalación nueva con el anillo preparado, `sistema --login-api` falla con `AnilloSinAncla` a mitad del verbo (prueba SF03): la base y S1 quedan hechos, sin InstalacionId ni marca. **Avisar a A antes del 5-nov** (orden de `FaseEsquema`). |
| SF-04 | Baja | Si la fila del ancla no se puede leer al arrancar, la API solo registra un aviso y sigue con DPAPI, sin falla cerrada (`ComprobacionAnillo.cs:83-92`, prueba SF04). |
| SF-05 | Baja | Una instalación que ya usaba el anillo con certificado por claves sueltas, con llaves en `Api\anillo`, deja de arrancar al actualizar a F1; si su certificado no pasa el descriptor exacto, `--preparar` crea un segundo principal y sale con 2 (la ceremonia de recuperación). |
| SF-06 | Media | La llamada a G-1 y a G-2 en `GPOS.Migracion/Program.cs` no tiene prueba: si se quita, ninguna falla (MC-23 y MC-24 sobreviven). |
| SF-07 | Baja | Cinco pruebas faltantes, todas por mutantes que sobreviven: la regla de una sola fuente solo se prueba en 2 de las 5 claves (MC-07); se acepta el control total traducido para la cuenta del servicio (MC-09); nada prueba el sobre de prueba del paso 9 (MC-18); un certificado vencido pasa como «ya estaba» (MC-29); nada prueba el aviso de 180 días en `--preparar` (MC-31). |
| SF-08 | Baja | El esquema del archivo admite rutas UNC y huellas anteriores repetidas o iguales a la vigente (D-AN-13 y D-AN-14 siguen abiertas). |
| SF-09 | Informativa | `DescriptorLlave.Comprobar` no exige la DACL protegida, aunque `Crear` sí la pone. |

**Estado de lo firmado.** SA-01: cerrada en `--preparar` y `--anclar` (MC-01 y MC-02b muertas); el `.cer` se lee una sola vez. SA-02: cerrada (MC-03 muerta; no verifiqué el procedimiento de P-2 —30 años, 3072 bits, AES-256—, que es un documento). SA-03: cerrada en sus tres partes (MC-04, MC-05 y MC-11 muertas) con los residuos SF-04 y SF-05. SA-06: cerrada en lo firmado (`--comprobar` sale con 2; MC-12 muerta; la parte de `comprobar-servidor` es de A). SA-11: cerrada para el 4704 (el mensaje no vuelca valores). SA-15: cerrada para F1 (fuera de Windows falla antes de leer el archivo). SA-10: cerrada solo en parte (las 5 claves del anillo; el resto es de A). SA-12 y SA-14: siguen abiertas. QA-AN-02, 03 y 05: cerradas; QA-AN-01, 04, 06 y 07: siguen abiertas. K-01 a K-17 se cumplen en el código (K-01 y K-02 esperan la confirmación en la VM; K-10 y K-11 tienen los huecos SF-02 y SF-06). El 4704 es único y el 4729 ya no aparece en `src`.

**Qué meter en F1:** SF-01 a SF-04 y SF-06, ~0,3 dp. Cuando corrijas, repito SF01a, SF01b, SF02 y SF03 invertidas, junto con MC-23 y MC-24, sobre el sha nuevo.

**Candidatas a ADR:** (1) huella dictada en todo verbo que fije o cambie el ancla (precisa H-17 v2 y SA-01; alternativa descartada: dejarla solo en `--preparar` y `--anclar`); (2) cuándo se escribe `Licencia.InstalacionId` con el anillo con certificado (precisa C-08 y el 3.3 del blueprint). Pregunta al propietario por el Arquitecto Maestro sobre SF-01.

**Supuestos:** el alcance de SA-01 es el firmado (yo propongo ampliarlo); no hay instalaciones de producción con claves sueltas; lo marcado [I] se confirma en W-AN-01 y W-AN-02.

**Reparto:** B → SF-01 a SF-09 y la precisión del 3.3 y del 3.2; A → orden de `FaseEsquema` (SF-03), SA-10 (resto), SA-14 y `CodigoSalida`/`VencePronto` en `comprobar-servidor`.

Respuesta requerida: cerrar SF-01 y SF-03 (~0,2 dp) o aceptar el residuo por escrito del propietario; avisarme el sha nuevo.
