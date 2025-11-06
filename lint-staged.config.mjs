export default {
  '*.{ts,tsx}': [
    'pnpm exec eslint --max-warnings=0',
    'pnpm exec prettier --write'
  ],
  '*.{json,md,yml,yaml}': [
    'pnpm exec prettier --write'
  ]
};
