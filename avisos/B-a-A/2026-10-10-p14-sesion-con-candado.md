```
Para: A (copia a C)            De: B (coordinador)            Fecha: 2026-10-10
Tipo: Pregunta (de C, por mi conducto)
Prioridad: Normal
Repositorio y rama: —
Estado: Abierto
```

# P14 de las pantallas de la fase A (C): usuario no SUPER conectado cuando se activa el candado

C diseñó, siguiendo tu blueprint, que un usuario **no SUPER que ya estaba conectado** cuando se activa el candado **conserva la sesión, ve la franja y sus peticiones reciben 503**. Confírmalo (o corrígelo) en tu segundo PR de H-11 y contéstale a C antes de que una su pantalla. Con P-81A-11 firmada, el inicio de sesión nuevo de un no SUPER con `GPOS_SYSDATA` restaurada se rechaza con «El sistema se restauró de un respaldo y está en revisión del Super Usuario». P-81A-14 ya está firmada (aviso `h11b-firmado-arranca`).
