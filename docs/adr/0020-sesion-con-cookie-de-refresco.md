# ADR-0020 Esquema de sesión: cookie httpOnly de refresco

Estado: Aceptada e implementada (27-11-2026). Pendiente: revisión de cierre del agente `seguridad`. Define el "esquema definitivo" que ADR-0005/`frontend/CLAUDE.md` dejaban pendiente ("el token vive solo en memoria; el agente de seguridad define el esquema definitivo").

## Contexto
El access token JWT vivía solo en memoria en el frontend (nunca en `localStorage`/`sessionStorage`), a propósito: minimiza lo que un XSS podría robar. El costo era que recargar la página o cerrar y volver a abrir la pestaña cerraba la sesión, obligando a iniciar sesión de nuevo cada vez. El usuario pidió corregir esto sin reintroducir el riesgo de guardar el token donde JavaScript pueda leerlo.

## Decisión
1. **El access token sigue viviendo solo en memoria** (`AuthService.tokenActual`, un signal). No cambia.
2. **Nuevo refresh token**, de vida más larga (7 días, `jwt_refresh_expire_minutes`), que el backend entrega **solo como cookie `httpOnly`** (`refresh_token`, `Secure` fuera de desarrollo, `SameSite=Lax`, acotada a `path=/api/v1/auth`). Nunca se expone en el cuerpo JSON ni lo toca el frontend directamente: ni JavaScript ni un XSS pueden leerlo.
3. **`POST /auth/refrescar`**: sin pedir contraseña, valida la cookie y devuelve un access token nuevo (y renueva la cookie — sesión deslizante: el uso activo no expira a los 7 días, la inactividad sí). El frontend lo llama una sola vez, al arrancar la aplicación (`app.config.ts`, antes de que el router resuelva la primera ruta), y si falla (no hay cookie o venció) simplemente deja al usuario en el login, como hoy.
4. **`POST /auth/logout`**: borra la cookie en el servidor. El frontend lo llama al cerrar sesión, sin esperar la respuesta (la sesión ya terminó del lado del navegador).
5. Un refresh token no sirve como access token ni viceversa (claim `"tipo"` en el JWT, verificado en `usuario_actual` y en `refrescar_sesion`): defensa en profundidad si alguno se filtra por error.
6. Cambiar la contraseña (`PUT /auth/contrasena`) ya invalidaba los tokens anteriores (`credenciales_cambiadas_en`); ahora también reemite la cookie de refresco, para no cerrar la sesión actual de quien la cambió.
7. **Limitación conocida, aceptada**: no hay lista de revocación de refresh tokens. Una cookie robada sigue siendo válida hasta que expira (máx. 7 días) o el usuario cambia su contraseña. Suficiente para el alcance académico/sintético actual; si se necesita revocación inmediata (p. ej. robo de equipo), se resuelve más adelante con un registro de sesiones activas.

## Consecuencias
- `CORSMiddleware` ahora usa `allow_credentials=True` (ya exigía orígenes explícitos, nunca `"*"`, que es lo que el navegador pide para esto).
- El frontend manda `withCredentials: true` solo en `login`/`refrescar`/`logout` (las demás llamadas siguen autenticándose con `Authorization: Bearer` vía el interceptor existente).
- Contrato sin cambios visibles para quien consume la API con el header `Authorization` (el `TokenOut` de `/auth/login` es igual); solo se agregó un `Set-Cookie` de efecto secundario y dos endpoints nuevos.
- Pruebas: `backend/tests/test_auth.py` (cookie se pone en login, `/refrescar` sin cookie es 401, con cookie renueva sin contraseña, un access token no sirve de cookie de refresco, usuario desactivado no puede refrescar, `/logout` borra la cookie, cambiar contraseña renueva la cookie).
- `frontend/CLAUDE.md` y el comentario en `AuthService` se actualizan: ya no dicen "esquema pendiente".
