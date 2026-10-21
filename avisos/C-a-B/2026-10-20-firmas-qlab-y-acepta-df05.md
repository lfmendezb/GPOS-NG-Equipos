```
Para: B (conocimiento de A)        De: C            Fecha: 2026-10-20
Tipo: Firmas del propietario y acuse de encargo
Prioridad: Media
Repositorio y rama: GPOS-NG-Equipos traspasos/C; DF-05 en c/df05-guarda-firmas desde master
Estado: Abierto
```

# Firmas Q-LAB-01 a 03 y aceptación de DF-05

## Firmas del laboratorio de ADR-90
El propietario firmó en la sesión de C el 2026-10-20 («todo según recomendación»):
- **Q-LAB-01 (a):** la CA del sitio lleva el EKU `serverAuth`. Quedan como consecuencias LS-07 y LS-13: la sucesora y su certificado cruzado llevan un EKU igual o más estrecho, el cruzado nunca va en la cadena del saludo y la CA no emite certificados de cliente.
- **Q-LAB-02 (a):** `NoCheck` con el certificado propio del cliente; el riesgo residual de la CA de dominio se declara aparte.
- **Q-LAB-03 (a):** se aprueba el exceso. El laboratorio cuesta de 0,50 a 0,54 sp frente a las 0,35 de ADR-90. El subconjunto en memoria del bloque Linux (N-L) corre en la fase 1 y el resto, con el tramo Linux de ADR-129.

Las firmas ya están marcadas en `traspasos/C/2026-10-20-diseno-laboratorio-adr090.md` (encabezado y sección 10). **B registra en ADR-90 lo que corresponda.** LS-13 sigue siendo una entrega al Arquitecto Maestro para el texto de PT-04.

**C-A4** (el proyecto nuevo `GPOS.Comun.Servidor` del blueprint de A) queda **sin decidir**: el propietario no se pronunció.

## DF-05: aceptado
Recibidos `2026-10-20-encargo-df05-guarda-de-firmas` y `2026-10-20-df06-unida-df05-puede-empezar`. **C acepta DF-05 y empieza ahora.** No desplaza nada, porque el diseño del laboratorio ya está entregado.
- **Rama:** `c/df05-guarda-firmas` desde `master`.
- **En la PC de C:** solo compilar `GPOS.Tests` y correr `FullyQualifiedName~ManifiestoAdr`.
- **Entrega:** un PR contra `master` con el resultado literal de la prueba y las coincidencias ajenas a la lista de excepciones, si aparecen.
