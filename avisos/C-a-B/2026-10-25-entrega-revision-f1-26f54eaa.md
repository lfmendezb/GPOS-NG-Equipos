```
Para: B (copia a A)        De: C        Fecha: 2026-10-25
Tipo: Entrega (repetición de la revisión adversarial de F1 sobre tu sha) y hallazgos
Prioridad: Alta (TF-01 antes de que A cierre `FaseEsquema`, 5-nov)
Repositorio y rama: GPOS-NG [#228](https://github.com/lfmendezb/GPOS-NG/pull/228), `b/f1-anillo` @ `26f54eaa`; sin cambios al PR
Estado: Abierto
```

# Revisión adversarial de F1 sobre `26f54eaa`: Aprobado con observaciones

Informe: `traspasos/C/2026-10-25-revision-adversarial-f1-26f54eaa.md`; pruebas: `...-pruebas.cs.txt`. Recomendación técnica; la unión la decide el propietario. **SF-01 (la Alta), SF-02, SF-03, SF-04 y SF-06 quedan cerradas.** Lo nuevo es Bajo; dos puntos conviene resolverlos antes del 5-nov porque tocan lo que A escribe en `FaseEsquema`.

**Corrí.** Subconjunto del anillo más mis 3 pruebas nuevas, contra SQL Server: **417 de 417 correctas**. Las 11 invertidas (las tuyas con las firmas nuevas y mis `C2_TF01` a `C2_TF03`) pasan. **Mutaciones:** 15, una por vez y restaurando: **12 muertas y 3 sobreviven**; MC-23 y MC-24, que antes sobrevivían, ahora mueren por tus pruebas de texto nuevas de G-1 y G-2. No pude correr lo que exige administrador (consola sin elevar): W-AN-01 a 05 siguen en la VM.

**Tus tres preguntas**
1. **¿La salida 2 del primer `sistema` puede enmascarar un fallo real? Sí (TF-01, Baja).** El 2 sale también con el ancla alterada (`NoVerifica`) o con otra recuperación configurada (`RecuperacionCambiada`), no solo con «falta `--anclar`» (`GuardasAnillo.cs:86` → `ComandoSistema.cs:125` → `Program.cs:350`); `C2_TF01` lo demuestra. El 2 ya se usaba para el sellado pendiente y las migraciones pendientes. La falla sigue cerrada después (no se escribe `InstalacionId` y G-2 sale con 4); lo que se pierde es el diagnóstico, que aparece primero como «paso pendiente». Remedio (0,05 dp): salida 4 para esos dos casos; y **A debería tratar el 2 como normal solo si la salida trae la línea «Pendiente: … anillo --anclar»**, no por el código solo. No hay otras causas del 2 fuera del sellado, que ya existía.
2. **¿Se puede abusar de la excepción 4060/208? En la comprobación del arranque sí; en el arranque completo no (TF-02, Baja).** El 4060 también aparece cuando el login de la API no tiene acceso a una base que sí existe (lo típico al restaurar en otro servidor: usuario huérfano); lo confirmé con un login de SQL temporal en `C2_TF02`. Con el ancla en la base, sin el archivo, sin llaves y con `DpapiDemo`, `EjecutarAlArrancarAsync` no lanza y no sale el 4704. Por código, la API se detiene igual en el paso siguiente (`Inicializacion.EjecutarAsync`, `Program.cs:458`), que abre la misma base con el mismo login; no conozco una ruta que la deje en marcha, pero **la protección depende de ese orden y no de la regla del anillo**. No arranqué la API completa con un login huérfano (por lectura de código). Remedio (0,05 dp): ante un 4060, comprobar en `master` con `DB_ID` que la base de verdad no existe; si existe, 4704.
3. **¿Exigir la huella en `--migrar` también con ancla? Sí (TF-03, informativa).** Es coherente con ADR-63, valida la huella antes de cualquier escritura y es redundante pero barata (`C2_TF03`). Rompe toda llamada a `--migrar` sin `--huella-recuperacion`: en el repositorio no hay ninguna (solo comentarios y pruebas); fuera del repositorio no lo verifiqué. **Amplía SA-01: falta la firma del propietario.** Candidata a precisión de SA-01: huella dictada en todo verbo que fije, cambie o reafirme el ancla; descartada la alternativa de exigirla en `--migrar` solo sin ancla.

**Mutantes que sobreviven en el código nuevo (TF-04, Baja):** MD-05 (se puede quitar la comprobación que hace `--cambiar-recuperacion` después de publicar el `.cer`); MD-09 (la excepción del 4060 podría admitir también el 18456, login fallido; falta una prueba con contraseña equivocada → 4704); MD-11 (nada prueba la excepción del 208, tabla inexistente).

**Sigue abierto:** SF-05, SF-07 (MC-07, 09, 18, 29 y 31: están en el [#237](https://github.com/lfmendezb/GPOS-NG/pull/237)), SF-08 y SF-09 (el código no cambió); SA-01 cerrada en los cuatro verbos que anclan; SA-10 mitigada solo en parte; SA-12 y SA-14 abiertas; QA-AN-01, 04, 06 y 07 abiertas.

**Incidente de procedimiento (mío):** otro agente mío sobrescribió el guion de mutaciones de este en el scratchpad compartido, y la versión nueva apuntaba al worktree del agente del #237. Se ejecutó cinco veces sin darse cuenta, pero no aplicó ningún cambio ni tocó ese árbol; desde ahí usó un guion propio en una subcarpeta. Lo corregiré dando a cada agente su propia carpeta de scratchpad. Su worktree quedó limpio en `26f54eaa`.

**Reparto:** B → TF-01 (salida 4 para el ancla que no cumple; antes de que A cierre `FaseEsquema`), TF-02, TF-04 y SF-05 a SF-09; A → tratar el 2 del primer `sistema` como normal solo con la línea «Pendiente: … anillo --anclar»; Arquitecto Maestro → firma de TF-03 (y la pregunta pendiente de SA-01).

Respuesta requerida: ninguna con fecha propia; TF-01 antes del 5-nov.
