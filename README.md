## CLI (opcional)
O projeto já funciona **sem** instalar o CLI global. Use localmente:
```bash
pnpm --filter @mini-ide/cli build
node packages/cli/dist/index.js analyze --base "http://127.0.0.1:3200" --input "Olá Mini-IDE!" --maxLen 10
```
