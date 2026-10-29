# Carpeta Viva

Sistema de gestión documental para hogares sustitutos del ICBF, con base de datos semántica para uso de IA. Este repositorio es el de gobierno: contexto, decisiones, plan, agentes, ontología e infraestructura.

Empiece por `CLAUDE.md`, `docs/modulos.md` y `docs/plan-por-fases.md`.

## Estructura
```
CLAUDE.md  CUESTIONARIO.md  Contexto/  docs/  ontologia/
.claude/agents/   agentes (8)
infra/            Nginx y scripts de PostgreSQL
docker-compose.yml  .env.example  scripts/
backend/          repositorio propio (FastAPI)
frontend/         repositorio propio (Angular)
```

## Arranque
```
scripts/bootstrap.sh          # Windows: scripts\bootstrap.ps1
# completar .env
cd frontend && npm install && npm run build && cd ..
docker compose up -d --build   # abre http://localhost:8080
```
Ver estado de la verificación en `docs/plan-por-fases.md` (Fase 0).
