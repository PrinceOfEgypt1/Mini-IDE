## CLI (opcional)
O projeto já funciona **sem** instalar o CLI global. Use localmente:
```bash
pnpm --filter @mini-ide/cli build
node packages/cli/dist/index.js analyze --base "http://127.0.0.1:3200" --input "Olá Mini-IDE!" --maxLen 10
```

## Scripts oficiais
- `17_dev_all.sh` — sobe o ambiente de desenvolvimento.
- `42_pipeline_checklist.sh` — valida build/typecheck/lint/tests e endpoints (`/healthz`, `/analyze`).
- `46_safe_tag_and_push.sh` — cria tag e publica (release).
> Todos os demais scripts foram arquivados em `scripts/`. Evite executá-los.

