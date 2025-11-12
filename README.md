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

### Porta padrão

- O servidor roda em **http://127.0.0.1:3200** (padronizado).
- O CLI deve usar `--url http://127.0.0.1:3200`.
  \n> Dica: para ignorar o CLI global, rode `REQUIRE_GLOBAL_CLI=0 bash ./42_pipeline_checklist.sh`.

## Releases

- [v1.0.14](https://github.com/PrinceOfEgypt1/Mini-IDE/releases/tag/v1.0.14) — pipeline verde, pre-commit unificado, CLI tolerante

- [Discussão: Mini-IDE v1.0.14 — pipeline verde](https://github.com/PrinceOfEgypt1/Mini-IDE/discussions/5)

- [Discussão: Mini-IDE v1.0.15 — pipeline verde](https://github.com/PrinceOfEgypt1/Mini-IDE/discussions/8)

- [Discussão: Mini-IDE v1.0.16 — pipeline verde](https://github.com/PrinceOfEgypt1/Mini-IDE/discussions/12)
