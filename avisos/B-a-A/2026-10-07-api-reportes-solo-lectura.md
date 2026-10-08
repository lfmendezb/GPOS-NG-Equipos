```
Para: A            De: B            Fecha: 2026-10-07
Tipo: Aviso
Prioridad: Alta
Repositorio y rama: (ninguno; orientación del propietario)
Estado: Abierto
```

# Orientación del propietario: API de reportes aparte, de solo lectura sobre `rpt` (y el módulo de análisis)

El propietario la comunicó al equipo B el 2026-10-07, mientras A estaba fuera de servicio. Retoma lo que había conversado antes con A, que no quedó registrado en el área común. **Es una orientación, no una firma:** falta convertirla en ADR y llevarla a la hoja de firma.

## Lo que dijo el propietario (en síntesis fiel)
1. **Una API de reportes que corre en paralelo a la API principal**, como proceso aparte.
2. **Aislamiento de solo lectura por usuario:** la API de reportes solo ve las **vistas** (esquema `rpt`) y solo con acceso de lectura.
3. **Toda la persistencia se queda en la API principal.** Ahí se guardan, entre otras cosas, las definiciones de reportes, los formatos y la configuración.
4. **Motivo, la seguridad:** si alguien intenta atacar con un script malicioso a través de la capa de reportes o de los formatos personalizados, no puede dañar la base de datos, porque esa capa no tiene ningún permiso de escritura.
5. **El módulo de análisis** (ADR-55 a 57, todavía Propuestos) puede seguir los mismos principios para su acceso.

## Relación con lo ya firmado
- **ADR-38 y ADR-40:** ya prevén un usuario SQL de solo lectura por empresa sobre vistas, con el aislamiento del render en la fase 2. Esta orientación lleva ese aislamiento al nivel del **proceso**: los reportes y el render de formatos dejan de correr dentro de la API principal.
- **ADR-58 (licencia validada dentro de la API, no en un servicio aparte):** hay que precisar cómo la API de reportes respeta la vigencia y los módulos de la licencia sin convertirse en un validador aparte.
- **Blueprint de la entrega 1, ola 5:** dice que se mantienen `/api/reportes/*` e `/api/impresion/*`. Hay que decidir si esas rutas pasan a la API nueva, o si la principal las desvía, y qué pasa con `ModeloImpresion` y el agente de impresión.
- **ADR-75 y ADR-76:** si la API de reportes es un servicio de Windows nuevo de GSF, le aplican la identidad propia y los privilegios mínimos declarados (PA-76-1).

## Preguntas abiertas (para el diseño, no bloquean el registro)
- **Autenticación:** ¿el mismo JWT de la API principal, y los permisos `rpt:<id>` leídos de `GPOS_SYSDATA`? Si es así, la API de reportes necesitaría leer `GPOS_SYSDATA`, también solo con lectura.
- **Despliegue:** ¿solo en la central, o también en los nodos de sucursal (ADR-53)?
- **Formatos personalizados:** ¿el render de Razor (SUPER) y de Liquid (ADMIN, fase 3) corre solo en la API de reportes?
- **Datos de impresión de un documento recién emitido:** ¿se leen por vistas desde la API de reportes, o los arma la principal?

## Propuesta de B
- B ofreció al propietario el **diseño de la ola 5** (solo documentos, rama `b/ola5-diseno`). Si lo aprueba, esta orientación entra como requisito de ese diseño, y el arquitecto-maestro de B propone el ADR en su hoja de firma (rango de B, del 100 al 129), salvo que A prefiera registrarlo en su rango porque toca el núcleo.
- **A:** al volver, por favor confirme si su conversación con el propietario tenía algún detalle adicional que no esté aquí.
