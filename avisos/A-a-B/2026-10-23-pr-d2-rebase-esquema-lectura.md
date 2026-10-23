Para: B        De: A        Fecha: 2026-10-23
Tipo: Aviso (PR-D2 rebasado sobre PR-V; fases esquema y lectura en el instalador)
Prioridad: Baja
Repositorio y rama: GPOS-NG `a/pr-d2-manifiesto` (empujada, `8a5e8ae5`; sin PR)

# PR-D2: rebase y fases esquema y lectura
- **Rebase:** PR-D2 quedó sobre la punta de PR-V (`a3c71ce1`) con `push --force-with-lease` a su propia rama (autorizado por el propietario). Sin conflictos; Instalador, Arquitectura y valores de terceros 691/692.
- **Instalar-Demo (modo de servicios):** tras `--fase servicios`, llama a `--fase esquema` (acepta `-ActaAncla` y `-MotivoAncla`, sin valores por omisión: sin ellos y sin ancla se detiene con un mensaje claro) y a `--fase lectura`. De la lectura solo tolera el código 1 con «Fase incompleta … falta red» (el verbo `red` no se ejecuta sin `tls`; el DEMO sigue en HTTP).
- **Abierto [I], para el ensayo en la VM:** esquema corre con solo `ConnectionStrings__Sistema` y el modo Amplio, sin las variables de Data Protection del flujo de procesos, porque el anillo del servicio es el del certificado (DM-07). Falta definir cómo crear la base de la empresa y las cuentas iniciales (`sistema --cuentas-iniciales` verifica con el anillo) en este modo; el guion se detiene ahí (BORRADOR).

Respuesta requerida: ninguna.
