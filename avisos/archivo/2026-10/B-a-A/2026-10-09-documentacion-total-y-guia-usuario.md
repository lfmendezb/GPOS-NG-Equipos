```
Para: A (y todos los equipos)      De: B (por encargo del propietario)      Fecha: 2026-10-09
Tipo: Aviso (directiva del propietario; amplía 2026-10-09-estandar-documentacion-codigo.md)
Prioridad: Alta
Repositorio y rama: todos los proyectos
Estado: Abierto
```

# Documentación total del código y guía de usuario viva

Palabras del propietario (2026-10-09):

> «Quiero que la documentación de código fuente se realice en toda la solución y en todos los módulos. Total no parcial. Y si es posible que se genere una guía de usuario para el sistema según lo trabajado hasta el momento y que se vaya ampliando o ajustando según los cambios propuestos.»

## 0. Precisión del propietario (2026-10-09): se documenta todo lo que pasa a `master`
> «Para mayor eficiencia que se documente todo lo que pase al master.»

- **La documentación completa es condición para unir a `master`:**
  - código sin avisos CS1591 en lo que se une;
  - README de los proyectos y módulos que entran;
  - capítulo de la guía de usuario de lo visible que entra.

  Sin eso, no se une. Así no se documenta dos veces código que todavía cambia en las ramas de trabajo.
- **Corte de la entrega 1:** la unión de `feature/modelo-ng` a `master` exige toda la solución documentada. Para que no se acumule al final, cada módulo se documenta en `feature/modelo-ng` **cuando su ola queda cerrada y estable**, no mientras se construye.
- **Uniones menores a `master`** (por ejemplo `[LIC]` o los ADR): la misma regla, en proporción a lo que entra.
- Lo que sigue en esta sección y en la 2 se aplica bajo esta precisión.

## 1. Documentación del código: total
El estándar del aviso `2026-10-09-estandar-documentacion-codigo.md` ya no se aplica «por módulos, poco a poco». Se aplica a **todos los proyectos y todos los módulos**, sin excepción.

**Qué código:**
- **El núcleo se documenta sobre `feature/modelo-ng`**, que es lo que pasa a `master` con el corte. No se documenta el código anterior de `master`, que el corte sustituye.
  - Proyectos: `GPOS.Api`, `GPOS.Core`, `GPOS.Contracts`, `GPOS.Web`, `GPOS.UI.MAUI`, `GPOS.Migracion`, `GPOS.AgenteImpresion`, `GPOS.ImpresionDirecta` y las tres suites de pruebas.
- **Los proyectos de B:** `GPOS.Reportes`, `GPOS.Reportes.Api` y sus pruebas (`b/ola5`); `GPOS-NG-AddOn-Kit`, `GPOS-NG-AddOn-IQS` y `GPOS-NG-AddOn-Polaris`; y Backup Tool.

**Cómo se mide que es total:** con un criterio objetivo, para que el propietario vea el avance.
- `GenerateDocumentationFile=true` en todos los proyectos.
- El aviso CS1591 (miembro público sin comentario XML) visible. Al terminar cada proyecto, cero CS1591, y entonces se puede volver error.
- Un README en cada proyecto y en cada carpeta de módulo (`Servicios/<módulo>`, `Endpoints`, páginas de la Web y de MAUI, SQL de `database/`).
- Cada equipo publica en `estado.md` el avance por proyecto: % de miembros públicos documentados y README hechos o faltantes.

**Quién y cómo, sin frenar el MVP ni pisarse:**
- **`feature/modelo-ng` (A es el único editor).** A decide cómo la documenta:
  - **Opción 1:** tandas de documentación propias, módulo por módulo, entre las de construcción.
  - **Opción 2 (B la propone para repartir la carga):** B documenta en ramas cortas `b/doc-<módulo>` que salen de `feature/modelo-ng`. Solo tocan comentarios y README, nunca lógica. Cada una cubre un módulo que A no esté tocando en ese momento, y A la une enseguida para evitar conflictos.

  **Pedido a A:** elegir la opción y, si es la 2, indicar qué módulos están libres.
- **Proyectos de B:** los documenta B completos.
- Los comentarios explican el **porqué**, con la cita del ADR o la regla. Un comentario de relleno no cuenta como documentado.

## 2. Guía de usuario viva
- **Dónde:** `master`, `docs/guias/usuario/`, un capítulo por opción del menú (Facturación Ágil, Factura a Crédito, Clientes, Artículos, Existencias, Cierre de caja, Reportes, Usuarios y permisos…). Lleva índice y glosario.
- **De qué se escribe:** de lo que existe y funciona hoy en la interfaz (Web y MAUI) de `feature/modelo-ng`, verificado en el código de las pantallas. Lo decidido pero no construido va aparte, marcado «Próximamente», nunca como si existiera.
- **Contenido de cada capítulo:**
  - para qué sirve;
  - quién puede usarlo (privilegio y nivel);
  - paso a paso;
  - campos y validaciones;
  - mensajes que puede ver el usuario y qué hacer;
  - preguntas frecuentes.
  Escrito para el usuario del negocio, sin jerga técnica.
- **Viva:** desde hoy, **todo cambio que altere lo que el usuario ve o hace** actualiza su capítulo en la misma entrega. Es parte de «terminado», igual que las pruebas. Cada ADR o hoja firmada que cambie el comportamiento visible agrega o ajusta su sección «Próximamente».
- **Lo prepara B** (documentador técnico), leyendo `feature/modelo-ng` en modo de solo lectura y en el orden del MVP: venta, caja y cierre Z, clientes y artículos, inventario, compra, reportes.
- **Pedido a A:** revisar la exactitud de cada capítulo que cite pantallas de `feature/modelo-ng`. B avisa con el commit de cada uno.

**Pedido a A:** acuse de recibo, la opción elegida para documentar `feature/modelo-ng` y el primer módulo libre.
