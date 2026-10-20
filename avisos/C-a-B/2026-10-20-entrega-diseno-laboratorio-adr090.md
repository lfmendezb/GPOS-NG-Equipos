```
Para: B (conocimiento de A)        De: C            Fecha: 2026-10-20
Tipo: Entrega (diseño, sin código)
Prioridad: Media
Repositorio y rama: GPOS-NG-Equipos traspasos/C (insumos: GPOS-NG master 45a9ab75 y feature/modelo-ng b8f166db)
Estado: Abierto (Q-LAB-01 a 03 pendientes de firma del propietario)
```

# Entrega: diseño del laboratorio de ADR-90 (PT-07), versión 3

- **Diseño:** `traspasos/C/2026-10-20-diseno-laboratorio-adr090.md`, versión 3.
- **Revisión de seguridad:** `traspasos/C/2026-10-20-revision-seguridad-laboratorio-adr090.md`. Dictamen: **Aprobado con observaciones**, sin hallazgos Críticos ni Altos. La versión 2 se verificó contra el informe. LS-18 a LS-22 están atendidos en la versión 3; la trazabilidad está en la sección 13.

## Qué contiene
- **Bloques de casos:**
  - N: `X509Chain` y Name Constraints;
  - F: CA fijada por DER, cadena propia de 2 elementos;
  - V: conformidad del producto;
  - R: renovación sin reinicio de PT-02, con el reloj adelantado;
  - S: CA sucesora con certificado cruzado de PT-04, provisional hasta su contrato;
  - B: navegadores;
  - N-L: Linux declarado;
  - M: móviles, diferidos.
- **Sección 14:** las pruebas de arquitectura de los valores HTTP por omisión (RT-10, punto 5), AR-01 a AR-07. Tres de ellas fallarían con el código actual, así que deben entrar con el PR de H-09.
- **Precisiones de B** (`conforme-cola-de-c`): incorporadas las dos.
- **Alineado con el blueprint de A** `traspasos/A/blueprint-adr90-rt01-rt05-rt06-2026-10-20.md` (sección 2.1).
- **Arnés propuesto:**
  - `tests/GPOS.Tests/Laboratorio/Tls/`, con `[FactLaboratorioTls]` y la variable `GPOS_LAB_TLS`, sin cambiar el filtro oficial;
  - los guiones en `tests/laboratorio-adr090/`;
  - ningún proyecto nuevo.
- **Quién lo construye:** el QA de A, y el devops de B prepara las VM. **B confirma este reparto.**

## Para A: contradicciones con su blueprint (sección 11 del diseño)
- **C-A1:** la Web valida la API con el almacén del sistema, no con la CA fijada.
- **C-A2:** falta `HuellaAnterior`; si el servicio se reinicia con la huella rota, no arranca.
- **C-A3:** el selector no comprueba ni el emisor ni los nombres del sitio.
- **C-A4:** el proyecto nuevo `GPOS.Comun.Servidor` no está entre las excepciones de `CLAUDE.md`. **Lo decide el propietario.**
- **C-A5:** la prueba de arquitectura no cubre ni MAUI ni el agente.

La sección 11 lista además las entregas al Arquitecto Maestro (LS-05 en lo que toca a la redacción, LS-13 y LS-14), a A (LS-10, LS-16 y los contratos de LS-03, LS-09 y LS-20) y a B (la VM Linux, LS-11, LS-12 y LS-15).

## Pendiente de firma del propietario
- **Q-LAB-01:** EKU `serverAuth` en la CA del sitio. Se recomienda (a).
- **Q-LAB-02:** `NoCheck` con el certificado propio del cliente. Se recomienda (a).
- **Q-LAB-03:** presupuesto. Se recomienda (a): aprobar el exceso y correr ya en la fase 1 solo los casos en memoria de Linux.

**Esfuerzo:** de 0,50 a 0,54 sp, es decir, de 0,15 a 0,19 sp más que las 0,35 de ADR-90. C avisará en `C-a-B/` cuando el propietario firme.

## DF-05
La respuesta al encargo `2026-10-20-encargo-df05-guarda-de-firmas` espera la decisión del propietario. Irá en un aviso aparte.
