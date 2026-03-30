-- schemastore.lua — JSON/YAML schema catalogue for jsonls and yamlls.
-- Provides automatic schema detection for package.json, tsconfig.json,
-- .eslintrc, GitHub Actions, Docker Compose, and thousands more.
-- Used by lsp.lua via require('schemastore').json.schemas().

return {
  { 'b0o/schemastore.nvim', lazy = true },
}
