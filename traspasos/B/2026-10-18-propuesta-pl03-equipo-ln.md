# Propuesta para firma: qué equipo hace LN (neutralizar el núcleo para Linux) en enero de 2027

**Estado:** Propuesta de B, pendiente de la firma del propietario. **Origen:** PL-03 (a) está firmada (LN en enero de 2027, punto de control, LS y LC en febrero y marzo, agente de impresión en el tramo 3b; DB-7 siempre antes). Falta decidir **quién** hace cada tanda. C lo sugirió en su tabla de la sección 6 (`traspasos/C/propuesta-adr-plataforma-linux-2026-10-18.md`); esta hoja lo confirma o lo cambia. Todas las cifras son *inferidas*.

## Recomendación (según la propuesta de C, con una precisión de B)
| Tanda | Qué | sp | Quién | Cuándo |
|---|---|---|---|---|
| H-L1 y H-L2 | Falla cerrada fuera de Windows | 0,05 | **A** (ya construida: #76, unida el 2026-10-18) | hecho |
| `ILlaveFirmaTokens` | Costura de la llave de firma del token | 0,1 | **B**, dentro de D2 de DB-7 | noviembre |
| LN1 a LN3 | Rutas, secretos, canal local y comprobación de carpetas detrás de interfaces | 0,95 | **A** | enero de 2027 |
| LS1 a LS4 | Secretos, canal y carpetas en Linux; SQL Server en Linux | 1,45 | **A** (LS4 con el arquitecto de datos) | febrero y marzo |
| LS5 | Paquetes, unidades, guía, ensayo, revisión de seguridad y QA | 0,8 | **B** (devops) con auditor y QA | marzo |
| LC1 a LC3 | Kit de conectores, conectores AdmCloud e IQS, Backup Tool | 0,8 a 1,0 | repositorios de los conectores y de Backup Tool | marzo y abril |
| LA1 a LA4 | Agente de impresión en Linux | 1,15 | **quien construya el tramo 3b** | tramo 3b |

## Por qué A para LN y LS
- LN y LS tocan lo que A escribió: el anillo (H-17 v2), los sellos y el padrón (ADR-83), las carpetas (ADR-77) y la identidad SQL (ADR-82). Un dueño por zona evita repetir los choques de la cadena de uniones.
- **Precisión de B:** en enero B está construyendo DB-7 (D1 a D6, hasta el 2026-12-11) y su cierre; A queda libre después de la fase A de ADR-81 y de RSV, y la fase B de ADR-81 va antes de LS. Si la fase B de ADR-81 la hace A, **LN puede ir en paralelo** (no tocan los mismos archivos); LS espera a que la fase B esté unida. Si A está saturado, el plan B es pasar LN a **C** (ya conoce la propuesta; son interfaces, no criptografía), con revisión de A, sin correr suites largas en su equipo.

## Qué se pide
- [ ] **Según la recomendación** (A hace LN y LS; B hace LS5; el agente, con el 3b)
- [ ] LN a C con revisión de A
- [ ] Otro reparto (indicar)

**Qué rompe:** nada (es un reparto interno). **A quién afecta:** a A (carga de enero y febrero). **Por qué se justifica:** un dueño por zona; no compite con el corte. **Cómo se migra:** no aplica.
