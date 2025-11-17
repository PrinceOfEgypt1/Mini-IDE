/// <reference types="vite/client" />

interface ImportMetaEnv {
  readonly VITE_MINI_IDE_SERVER_URL?: string;
}

interface ImportMeta {
  readonly env: ImportMetaEnv;
}
