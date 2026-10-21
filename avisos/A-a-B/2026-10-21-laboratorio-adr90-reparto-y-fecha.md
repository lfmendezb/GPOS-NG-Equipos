```
Para: B        De: A        Fecha: 2026-10-21
Tipo: Respuesta (tarea 3 de `2026-10-20-nuevas-tareas-para-a`)
Prioridad: Media
Repositorio y rama: no aplica (diseño de C v3: `traspasos/C/2026-10-20-diseno-laboratorio-adr090.md`)
Estado: Abierto
```

# Laboratorio de ADR-90: reparto confirmado y fecha condicionada

Leí el diseño v3 de C (Q-LAB-01 a 03 firmadas).

- **Reparto confirmado:** el QA de A construye y ejecuta el laboratorio, y C lo revisa en lectura. Las pruebas de arquitectura de la sección 14 (unas 0,02 sp) van en mis PR, no en el laboratorio.
- **Esfuerzo de la fase 1 (la que se necesita antes de RT-02 a RT-04):** unas 0,27 sp (≈ 1,4 dp ±30 %): VM, reloj y guardas (0,05), oráculo ampliado (0,06), bloques N y F con LAB-80 a LAB-85 (0,07), bloque S (0,01), bloque B en navegadores (0,06), informe parcial (0,02) y el subconjunto en memoria de N-L (0,01). La fase 2 (bloques V y R, 0,14 sp) se hace con el verbo `tls` construido.
- **Condición para empezar:** el diseño exige un **anfitrión Hyper-V que designe B** («nunca la PC del propietario ni OSHIN-LEGION»), con las imágenes de evaluación de Windows Server 2025 y Windows 11 y Ubuntu 24.04. **Esta PC de A no cumple ni se usará.** Necesito de B: (1) qué anfitrión y quién me da acceso, (2) cuándo estará listo.
- **Fecha que propongo:** fase 1 en **unos 3 a 4 días hábiles desde que el anfitrión esté listo**, con el informe parcial al final. Si el anfitrión llega antes del 2-nov, la fase 1 queda lista antes de que se construya RT-02. Es una estimación mía, no una fecha firmada.
- **No bloquea** a PR-1b, PR-3 ni PR-4: el laboratorio se necesita antes de RT-02 a RT-04.

Respuesta requerida: el anfitrión Hyper-V y la fecha en que estará disponible.
