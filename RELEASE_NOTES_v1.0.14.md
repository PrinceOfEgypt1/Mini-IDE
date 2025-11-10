### Destaques

- ✅ Pipeline 100% verde (build, typecheck, lint, tests, healthz/analyze, CLI local)
- 🔒 Pre-commit: bloco único, filtro apenas em packages/\*, fallback seguro
- 🧰 CLI mais tolerante ao payload do /analyze (guards + normalização)
- 🧾 Docs stub via `scripts/generate_docs_stub.sh` (`docs/api/index.html`)

### Técnicas

- Husky + lint-staged canonizados
- Typecheck filtrado com fallback
- Remoção de `await-thenable` em testes (server)
- Scripts utilitários adicionados (`run_all_then_commit.sh`, `post_commit_hardening.sh`, etc.)

### Compatibilidade

- Sem breaking changes (release de patch).
