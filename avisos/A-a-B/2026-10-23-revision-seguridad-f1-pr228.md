Para: B (copia para C)        De: A        Fecha: 2026-10-23
Tipo: Entrega (revisión de seguridad de F1, PR #228) y pregunta de firma
Prioridad: Alta (unión antes del 5-nov)
Estado: Abierto
Repositorio y rama: GPOS-NG `b/f1-anillo` @ `e1c6f516`

# Resultado: Aprobar con condiciones (sin Críticos ni Altos; 1 Medio y 6 Bajos)
Informe: `traspasos/A/revision-seguridad-pr228-f1-anillo-2026-10-23.md`. Revisión **por lectura**: no compilé ni corrí pruebas, así que las cifras de B (216/216 y 429/429) no las comprobé. La recomendación técnica es de A; la firma es del propietario.

**Bien:** ACL de la llave (tres entradas exactas, fijada en la misma llamada que la crea y comprobada después), llave de máquina no exportable, RSA 3072, 5 años; archivo del anillo con falla cerrada y una sola fuente; G-1 y G-2 con salida 4; SA-01 en `--preparar` y `--anclar`, SA-02, SA-03 y SA-06 como se firmaron; evento 4704 único en las ramas de origin; sin secretos en registros ni eventos.

| ID | Sev. | Hallazgo |
|---|---|---|
| R228-01 | Medio | `anillo --migrar` (sin ancla) y `--cambiar-recuperacion` anclan sin la huella dictada: SA-01 queda incompleta |
| R228-02 | Bajo | Si la fila del ancla no se lee al arrancar, solo hay aviso (solo con DPAPI); propongo falla cerrada en Release |
| R228-03 | Bajo | G-1 no cubre `sistema` sin opciones, que escribe `Licencia.InstalacionId` con el anillo |
| R228-04/05/06 | Bajo | DACL del archivo comprobada por ruta (no se revisan la raíz `GPOS NG` ni el `.cer`); el esquema admite rutas UNC; `--preparar` sin exclusión mutua |
| R228-07 | Bajo | Los textos de G-1 y G-2 omiten `--huella-recuperacion`; el aviso de 180 días reutiliza el evento 4717 |

**Condiciones para unir:** resolver R228-01 (o que el propietario acepte el riesgo con fecha), corregir R228-03 y los textos de R228-07. Los demás Bajos pueden quedar para F4. Yo reviso solo el cambio que B haga en `b/f1-anillo`.

# Pregunta de firma (R228-01)
¿Se **extiende SA-01** (huella dictada obligatoria) a `anillo --migrar` y `anillo --cambiar-recuperacion`? Propuesta de A: sí, `--huella-recuperacion` obligatoria en ambos (unas 0,25 dp); descartada: prohibir `--migrar` sin el archivo. Es una modificación de una firma del propietario: la lleva B.

# Para B, no son de seguridad
- G-1 bloquea los verbos del anillo en el DEMO actual con el servicio instalado hasta `--preparar`, y el archivo no se combina con `DpapiDemo`: confirma que es lo deseado.
- Con el archivo presente, `--cambiar-recuperacion` no tiene cómo recibir un `.cer` nuevo.

# Sin confirmar (supuestos)
Que el proveedor respete el descriptor al crear la llave (W-AN-02, VM) y que el `IConfiguration` de la API sea un `IConfigurationRoot` (si no, SA-03 al arrancar no actuaría).

Respuesta requerida: sí (firma de R228-01 y fecha de las condiciones).
