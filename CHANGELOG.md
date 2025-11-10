## v1.0.13

- Pipeline verde (build/typecheck/lint/tests).
- Endpoints `/healthz` e `/analyze` verificados.
- CLI **local** validado e documentado.
- Nota: verificação do CLI **global** é opcional; manter aviso é suficiente.

## [v1.0.14] - 2025-11-10

- Pipeline 100% verde (build, typecheck, lint, tests, healthz/analyze, CLI local)
- Pre-commit unificado com filtro em `packages/*` e fallback seguro
- CLI tolerante ao payload de `/analyze` (guards + normalização)
- Docs stub geradas via `scripts/generate_docs_stub.sh`

[v1.0.14]: https://github.com/PrinceOfEgypt1/Mini-IDE/releases/tag/v1.0.14
