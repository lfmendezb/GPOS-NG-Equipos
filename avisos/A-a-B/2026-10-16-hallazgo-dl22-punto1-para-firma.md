```
Para: B        De: A                          Fecha: 2026-10-16
Tipo: Hallazgo
Prioridad: Alta
Repositorio y rama: GPOS-NG a/dl22-rotacion @ 367128f0 (local; el PR sale tras corregir S02 a S06 y S08)
Estado: Abierto — espera la firma del propietario
```

# Hallazgo: el punto 7 de DL-22 (a) no se puede cumplir con el punto 1 firmado; precisión para firma

## Qué pasa
- **Medición del desarrollador**, en SQL Server 2019 con una base contenida temporal:
  - con `DENY CONNECT` a un usuario contenido, las sesiones ya abiertas fallan con el **916** en el lote siguiente;
  - las conexiones que el grupo reutiliza fallan con el **18456** en su primer comando;
  - cambiar la contraseña también rompe las conexiones reutilizadas.
- **Consecuencia:** la premisa del riesgo aceptado del 2026-10-15 («la generación anterior conserva sus sesiones durante el plazo») es falsa.
- **PA-30:** da de 6 a 10 respuestas 500 por rotación bajo carga (en 6 de 6 corridas). Ni el `KILL` diferido, ni `Connection Lifetime`, ni `ClearPool`, ni un plazo más largo lo evitan.
- **Causa (del arquitecto):** es de orden, no de plazo. La caché de cadenas de `EmpresasService` no vence, así que la API solo se entera de la rotación cuando algo le falla.

## Estado de la rama
- Los puntos 1 a 6 están construidos.
- PA-30 queda dividida en dos pruebas:
  - **sesiones cerradas al vencer el plazo:** en la suite, 5 de 5;
  - **«ningún 500»:** marcada `Transicion=Defecto`.
- Suite oficial: 3117 correctas, 5 fallidas y 18 omitidas. Las 5 son las del 12834.
- Seguridad: «Aprobado con observaciones» (`traspasos/A/revision-seguridad-dl22-rotacion-2026-10-16.md`). S02 a S06 y S08 se corrigen ahora, en la misma rama.

## Para la firma del propietario
**Precisión del punto 1 de DL-22 (a)**, en `traspasos/A/precision-dl22-punto1-2026-10-16.md` (v2, Propuesto):
- **(a):** la API renueva su caché cada 5 s; `DENY` a los 10 s.
- **(b):** cambio de contraseña en el acto; `DENY` y `KILL` al plazo; sondeo en cada apertura.
- **(b+):** caché de 1 s o menos; contraseña a los 3 s; `DENY` a los 15 s; `KILL` a los 2 min del `DENY`.

El arquitecto y el auditor recomiendan **(b+)**: unos 0,35 a 0,4 dp, sin costo permanente, y la credencial anterior deja de servir a los 3 s aunque el comando se interrumpa.

## Condiciones para unir el PR de DL-22 cuando salga
1. La descripción y la nota de ADR-82 dirán «implementado salvo el punto 7, pendiente de la precisión del 2026-10-16».
2. No registrar como cumplido el riesgo aceptado del 2026-10-15.
3. PA-30 «ningún 500» sigue en `Defecto` hasta la firma.
