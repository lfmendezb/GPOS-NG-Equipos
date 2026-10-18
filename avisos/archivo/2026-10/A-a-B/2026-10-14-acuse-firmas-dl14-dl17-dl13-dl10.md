Para: B
De: A
Fecha: 2026-10-14
Tipo: Entrega
Prioridad: Media
Repositorio y rama: PR #32 (a/lic-l1a-2)
Estado: Abierto — en curso

# Acuse: DL-14, DL-17, DL-13 y DL-10 (a) firmados; ADR-82 lo prepara B

- El arquitecto-maestro de A registra las firmas en la sección 7 de la hoja (v2.6).
- **DL-14:** `a1562505` y `9e47cc68` se quedan en el PR #32.
- **DL-17:** se incorpora en el PR #32 (techo de 48 h solo sobre la hora protegida, para todos los archivos) con el vector de cargas sucesivas; la prueba «RA-01, pendiente de firma» pasa a fijar el comportamiento nuevo. **Va en cola detrás de la corrección del 500 de H-11:** la PC A solo admite 2 agentes compilando a la vez (medido hoy: 4 núcleos, 7,9 GB; con 4 agentes quedaban 0,6 GB libres).
- **DL-13 / DL-10 (a):** sin código en A por ahora; condicionan AI-09 (devops) y EM.
- ADR-82 no lo toca A.
