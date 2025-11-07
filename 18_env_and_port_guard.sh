# 18_env_and_port_guard.sh
#!/usr/bin/env bash
set -euo pipefail
ROOT="$HOME/workspace/Mini-IDE"
SRV="$ROOT/packages/server"
cd "$ROOT"

# exemplo de env
cat > "$SRV/.env.example" <<'EOF'
# Porta padrão do servidor
PORT=3000
EOF

# guarda: se porta ocupada, loga orientação
awk '1' > "$SRV/src/portGuard.ts" <<'EOF'
import net from 'node:net';

export async function checkPortFree(port: number, host = '0.0.0.0'): Promise<boolean> {
  return await new Promise((resolve) => {
    const srv = net.createServer();
    srv.once('error', () => resolve(false));
    srv.once('listening', () => srv.close(() => resolve(true)));
    srv.listen(port, host);
  });
}
EOF

# injeta uso no index.ts
sed -i '1s/^/import { checkPortFree } from ".\/portGuard";\n/' "$SRV/src/index.ts"
sed -i 's/app.listen({ port, host: .*/(async () => {/' "$SRV/src/index.ts"
cat >> "$SRV/src/index.ts" <<'EOF'
  const free = await checkPortFree(port);
  if (!free) {
    console.error(`[mini-ide] porta ${port} já está em uso. Defina PORT para outra porta.`);
    process.exit(1);
  }
  await app.listen({ port, host: '0.0.0.0' });
  console.log(`[mini-ide] server running on http://localhost:${port}`);
})().catch((err) => {
  console.error(err);
  process.exit(1);
});
EOF

pnpm -F @mini-ide/server run build && pnpm -F @mini-ide/server run test
echo "== OK :: .env.example criado e guardião de porta ativado =="
