# Relatório Técnico — Mini-IDE (Bundle v1.0.13)
**Data/Hora:** 2025-11-06
**Projeto:** Mini-IDE
**Responsáveis:** Moisés + “Camaleão”

## TL;DR
- **Bundle validada:** v1.0.13
- **Pipeline (build → typecheck → lint → test → docs → sanity HTTP/CLI):** 100% verde
- **Artefatos:** TypeDoc em `docs/api/`; saídas do CLI local em `bundles/v1.0.12/`
- **Decisões de hoje:**
  - **Global CLI opcional**; check do CLI global rebaixado para *aviso*.
  - **Limpeza/arquivamento de scripts legados** (whitelist mínima mantida).
  - **README** ganhou seção “CLI (opcional)” e **CHANGELOG** v1.0.13.

## 1) Escopo desta release
- Monorepo PNPM: `analysis-agent`, `cli`, `server`, `shared`, `ui`.
- **Server (Fastify)** com `/healthz` e `/analyze` (CORS + guard de porta).
- **CLI** (`mini-ide analyze`) — **uso local suportado/validado**; link global é opcional.
- **TypeDoc** publicada localmente em `docs/api/`.

## 2) Ambiente e versões
- Node.js: **v22.21.1** | PNPM: **9.12.2** | Vitest: **4.0.7** | TS: **5.9.x** | Fastify 5 | TypeDoc 0.28.x

## 3) O que foi realizado
- Pipeline verde ponta a ponta (repetidas execuções).
- README atualizado (seção “CLI (opcional)”).
- CHANGELOG v1.0.13 criado.
- Limpeza de scripts: **mantidos** na raiz `17_dev_all.sh`, `42_pipeline_checklist.sh`, `46_safe_tag_and_push.sh`; **demais arquivados** em `scripts/archive-YYYYMMDD-HHMMSS/...`.
- Checklist: passo do **CLI global** agora é **aviso** e **não bloqueia**.

## 4) Status por pacote
- **server:** build/lint/tests OK; CORS/portGuard OK.
- **cli:** build/lint/tests OK; **uso local** validado.
- **analysis-agent:** build/lint/tests OK (compactPrompt).
- **shared** e **ui:** build/lint/tests OK (sanity).

## 5) Artefatos
- **Docs HTML:** `docs/api/index.html`.
- **Bundles CLI local:** `bundles/v1.0.12/analysis-*.json`.
- **Scripts oficiais (whitelist):** `17_dev_all.sh`, `42_pipeline_checklist.sh`, `46_safe_tag_and_push.sh`.

## 6) Pipeline (resultado)
- Build ✔️  Typecheck ✔️  Lint ✔️  Tests ✔️  Docs ✔️  HTTP sanity ✔️  CLI local ✔️

## 7) Decisões técnicas
- Testes do server com `app.inject()` (sem depender de porta/processo).
- Guardas no CLI para não encerrar o processo em testes.
- Relax do check de CLI global → **aviso**, não bloqueia release.
- Arquivamento versionado de scripts para evitar regressões.

## 8) Pendências moderadas
- (Opcional) Criar **GitHub Release** v1.0.13 com link para docs/CHANGELOG.
- (Opcional) Publicar docs via GitHub Pages.
- Remover `scripts/archive-*` no próximo ciclo (após carência).

## 9) Como usar (resumo)
- **Server local**: `pnpm --filter @mini-ide/server dev` → http://127.0.0.1:3200
- **CLI local**:
  ```bash
  pnpm --filter @mini-ide/cli build
  node packages/cli/dist/index.js analyze --base "http://127.0.0.1:3200" --input "Olá Mini-IDE!" --maxLen 10
  ```
- **Global (opcional)**: `cd packages/cli && pnpm build && pnpm link --global` (pode variar por ambiente; **local** é suportado).

## 10) Conclusão
A **v1.0.13** está **validada**. O **CLI local** é o caminho suportado. O check do CLI global foi rebaixado para **aviso**, e a limpeza de scripts reduz risco operacional sem perder rastreabilidade.
