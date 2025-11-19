#!/usr/bin/env bash
set -euo pipefail

FILE="DEVELOPMENT.md"

if [[ ! -f "$FILE" ]]; then
  echo "ERRO: $FILE não encontrado na pasta atual."
  exit 1
fi

# backup com timestamp
TS="$(date +%Y%m%d-%H%M%S)"
cp "$FILE" "${FILE}.backup-${TS}"

TMP_FILE="$(mktemp)"

awk '
function print_block() {
  print "5.6 UI – Playground /analyze e status do servidor"
  print ""
  print "A UI da Mini-IDE já está conectada ao Mini-IDE Server, com os seguintes recursos:"
  print ""
  print "- Configuração de servidor"
  print "  - A URL base do backend é lida da variável de ambiente `VITE_MINI_IDE_SERVER_URL`."
  print "  - O módulo `@mini-ide/ui/src/config/server.ts` centraliza `getBaseUrl()`, `getHealthzUrl()` e `getAnalyzeUrl()`."
  print ""
  print "- Indicador de status do servidor"
  print "  - O componente `ServerStatus` consulta `GET /healthz`."
  print "  - Estados visuais:"
  print "    - 🟢 Servidor online (200 em /healthz)"
  print "    - 🔴 Servidor indisponível (erro de rede ou status não-2xx)"
  print "    - ⏳ Verificando (requisição em andamento)"
  print "  - Integrado ao header da aplicação, seguindo o padrão visual do wireframe da Mini-IDE."
  print ""
  print "- Playground do endpoint POST /analyze"
  print "  - A aba **Analyze** do workspace contém o componente `AnalyzePlayground`."
  print "  - Permite enviar:"
  print "    - `text`: texto livre para análise (textarea)"
  print "    - `maxLen`: tamanho máximo do resumo (valor numérico, default 100)"
  print "  - A chamada é feita para `POST /analyze` usando a baseURL configurada."
  print "  - A resposta é exibida de forma estruturada (summary, inputLength, outputLength, requestId, timestamp) ou como mensagem de erro amigável em caso de falha."
  print ""
  print "Esses recursos formam o primeiro MVP de UI conectada ao backend, permitindo testar o contrato oficial do /analyze diretamente pelo navegador."
  print ""
}

BEGIN {
  in_old = 0
  inserted = 0
}

{
  # Se já existir uma seção 5.6 antiga, substitui pela nova
  if ($0 ~ /^5\.6 UI – Playground \/analyze e status do servidor/) {
    if (!inserted) {
      print_block()
      inserted = 1
    }
    in_old = 1
    next
  }

  # Ao entrar na seção 6., garante que 5.6 foi inserida antes
  if ($0 ~ /^6\. Pipeline local oficial/) {
    if (!inserted) {
      print ""
      print_block()
      inserted = 1
    }
    in_old = 0
  }

  # Enquanto estiver pulando a seção antiga, não imprime
  if (in_old) {
    next
  }

  # Demais linhas saem normalmente
  print
}

END {
  # Se por algum motivo não inseriu, adiciona no final
  if (!inserted) {
    print ""
    print_block()
  }
}
' "$FILE" > "$TMP_FILE"

mv "$TMP_FILE" "$FILE"

echo "[ok] DEVELOPMENT.md atualizado com a seção 5.6 UI – Playground /analyze e status do servidor."
echo "[ok] Backup criado em ${FILE}.backup-${TS}"
