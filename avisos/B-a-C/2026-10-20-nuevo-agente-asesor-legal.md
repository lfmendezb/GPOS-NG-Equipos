```
Para: C        De: B        Fecha: 2026-10-20
Tipo: Aviso (nuevo agente especializado; instalar en su PC)
Prioridad: Media
Repositorio y rama: GPOS-NG-Equipos main, `agentes/asesor-legal.md`
Estado: Abierto
```

# Nuevo agente: asesor-legal

El propietario pidió el 2026-10-20 sumar un agente especializado **asesor-legal**. La definición está en el área común: `agentes/asesor-legal.md` (copia de la de B; el README del área común dice que las definiciones las mantiene solo B).

## Cómo instalarlo en su PC
1. Copiar `agentes/asesor-legal.md` a `%USERPROFILE%\.claude\agents\asesor-legal.md`.
2. Reiniciar la sesión: la lista de agentes se carga al iniciar (igual que el hook del modelo por agente).
3. No modificar la definición en su PC; los cambios los propone a B.

## Qué es y qué no es
- **Modelo:** Opus (error legal caro); herramientas de lectura, escritura y consulta web.
- **Qué hace:** matrices de obligaciones, cláusulas candidatas y preguntas para el abogado colegiado del propietario; revisión legal de un diseño o cláusula. Todo documento abre con «Borrador de trabajo, no es asesoría legal; requiere la revisión de un abogado colegiado».
- **Qué no hace:** no es abogado, no emite dictámenes, no asesora a clientes finales, no firma ni envía nada por el propietario, no cita normas de memoria como hechos (marca «por confirmar por el abogado» lo que no verifica en fuente oficial), no modifica ADR ni `estado.json`.
- **Cuándo invocarlo:** antes de redactar cláusulas de un contrato, de decidir qué acceso a datos del cliente puede tener GSF (rol SUPER, solicitud válida por correo), de fijar retención o supresión, de definir qué sigue permitido con una licencia vencida, o cuando un diseño cree una obligación legal. No para tareas sin efecto legal.
- **Dónde deja su trabajo:** `docs/legal/` (y `docs/legal/revisiones/`). Sus documentos los revisa el propietario; ningún equipo los envía a terceros.

## Primer trabajo (de B)
Marco normativo dominicano verificado en fuentes oficiales: `docs/legal/2026-10-20-marco-normativo-verificado.md` (en curso; B avisa cuando se una a `master`). Insumo para la consulta del CI-7 (`docs/decisiones/2026-10-20-consulta-legal-ci7-borrador.md`, ya en `master`).

## Confidencialidad
No incluir datos personales ni de clientes en lo que se le pase para búsquedas web; usar casos genéricos.
