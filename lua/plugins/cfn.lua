-- CloudFormation support for cobi_cloud-infra, SCOPED to real CFN templates so
-- it never touches ordinary YAML (docker-compose, GH actions, k8s, etc.).
--
-- How the scoping works:
--   1. Content detection tags only genuine CFN templates as the compound
--      filetype `yaml.cloudformation` (the `yaml` base keeps yamlls + treesitter
--      highlighting; the `cloudformation` part is what cfn tooling keys off).
--   2. cfn-lint (nvim-lint) is registered ONLY under `cloudformation`.
--   3. cfn-lsp-extra (pip install cfn-lsp-extra) attaches ONLY to cloudformation
--      buffers, giving resource/property completion + hover.

-- Map the `cloudformation` filetype to the yaml treesitter parser.
pcall(vim.treesitter.language.register, "yaml", "cloudformation")

local function is_cfn(buf)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, 256, false)
  local text = table.concat(lines, "\n")
  if text:find("AWSTemplateFormatVersion", 1, true) then return true end
  if text:find("AWS::Serverless", 1, true) and text:find("Transform", 1, true) then return true end
  if text:match("\nResources:") and text:match("Type:%s*[\"']?AWS::") then return true end
  return false
end

-- Detect CFN templates and switch them to `yaml.cloudformation`.
vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
  group = vim.api.nvim_create_augroup("cfn_detect", { clear = true }),
  pattern = { "*.yaml", "*.yml", "*.template", "*.template.yaml", "*.template.yml" },
  callback = function(args)
    if vim.bo[args.buf].filetype:find("cloudformation") then return end
    if is_cfn(args.buf) then
      vim.bo[args.buf].filetype = "yaml.cloudformation"
    end
  end,
})

-- Start cfn-lsp-extra on cloudformation buffers. A user FileType autocmd glob-
-- matches the WHOLE filetype string (it does not split on "."), so we match
-- both the bare and the compound form set by the detector above.
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("cfn_lsp", { clear = true }),
  pattern = { "cloudformation", "yaml.cloudformation" },
  callback = function(args)
    -- nvim-treesitter's auto-enable doesn't match the compound filetype, so
    -- start the yaml highlighter explicitly.
    pcall(vim.treesitter.start, args.buf, "yaml")

    if vim.fn.executable("cfn-lsp-extra") ~= 1 then return end
    vim.lsp.start({
      name = "cfn_lsp_extra",
      cmd = { "cfn-lsp-extra" },
      root_dir = vim.fs.root(args.buf, { ".git", "Taskfile.yml", "template.yaml", "samconfig.toml" })
        or vim.fn.getcwd(),
    }, { bufnr = args.buf })
  end,
})

return {
  {
    "mfussenegger/nvim-lint",
    opts = function(_, opts)
      opts.linters_by_ft = opts.linters_by_ft or {}
      -- cfn-lint runs ONLY for the cloudformation filetype, not plain yaml.
      opts.linters_by_ft.cloudformation = { "cfn_lint" }
      -- Defensive: make sure no leftover cfn_lint sits on plain yaml.
      if opts.linters_by_ft.yaml then
        opts.linters_by_ft.yaml = vim.tbl_filter(function(l)
          return l ~= "cfn_lint"
        end, opts.linters_by_ft.yaml)
      end
      return opts
    end,
  },
}
