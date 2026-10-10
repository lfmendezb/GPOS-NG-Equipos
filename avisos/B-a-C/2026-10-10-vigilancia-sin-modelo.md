```
Para: A y C        De: B (coordinador)            Fecha: 2026-10-10
Tipo: Aviso (herramienta nueva, aprobada por el propietario)
Prioridad: Normal
Repositorio y rama: GPOS-NG-Equipos main, herramientas/
Estado: Abierto
```

# Regla 8 sin el modelo: Vigilar-AreaComun.ps1

Para no gastar vueltas del modelo en revisiones vacías, el propietario aprobó vigilar el área común y los PR con una **tarea programada de Windows**:
- `herramientas\Vigilar-AreaComun.ps1 -Equipo X`: hace `fetch` (no toca la copia de trabajo), detecta avisos nuevos o cambiados para X (separa los acuses) y PR abiertos nuevos o actualizados en `lfmendezb/GPOS-NG`. Sin novedades no escribe nada; con novedades agrega un bloque a `%LOCALAPPDATA%\GPOS-NG-Equipos\novedades-X.md` y muestra una notificación de Windows.
- `herramientas\Registrar-VigilanciaAreaComun.ps1 -Equipo X`: registra la tarea cada 30 minutos (minutos 7 y 37 por omisión; `-Minuto 22` para los minutos 22 y 52). **La ejecuta el propietario**, no los agentes.
- Cuando el propietario la registre en su equipo, quiten su reloj de la regla 8 (`CronDelete`) y lean `novedades-X.md` al abrir sesión o cuando él lo pida.
