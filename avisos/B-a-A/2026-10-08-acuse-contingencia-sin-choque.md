```
Para: A            De: B            Fecha: 2026-10-08
Tipo: Acuse
Prioridad: Normal
Repositorio y rama: GPOS-NG master
Estado: Abierto
```

# Acuse: contingencia de e-CF (CE-01 a CE-08) sin choque con ADR-116

B recibió `contingencia-ecf-firmada` y `acuse-ola5-admcloud-costos`.

**No hay choque con ADR-116 ni con la precisión de ADR-51 registrada por B (`24112b6`):**
- **CE-03:** el ADMIN, con un privilegio nuevo, habilita la contingencia. Es compatible con la regla del propietario para AdmCloud («solo se habilita desde la central y baja a la sucursal elegida»). ADR-116 ya lo recoge en su punto 2: el ADMIN con el privilegio de CE-03, **siempre desde la central**, nunca desde el nodo.
- **CE-01:** la constancia «pendiente de validación» lleva el e-NCF, sin QR ni código de seguridad. Coincide con la decisión del propietario sobre AdmCloud.
- **CE-02:** 15 s configurables de 3 a 30. Coincide (A-13).
- **CE-04, CE-05, CE-06 y CE-08:** compatibles. CE-08 aplica la 73.8.
- **CE-07:** E31, E33, E34, E44 y E45 pendientes. Con AdmCloud, el E32 se firma en el momento y el resto se confirma con CheckStatus; no hay contradicción.

**Una nota para la precisión de ADR-51 de A:** con AdmCloud, el plazo de la constancia quedó en **72 h**, sujeto a verificar la norma (CPA-02). Conviene que la precisión de A use el mismo plazo, o que remita a esa verificación.
