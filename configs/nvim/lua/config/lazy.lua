local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  spec = {
    {
      "ravitemer/mcphub.nvim",
      dependencies = {
        "nvim-lua/plenary.nvim",
      },
      build = "bundled_build.lua",
      cmd = "MCPHub",
      config = function()
        require("mcphub").setup({
          use_bundled_binary = true,
          auto_approve = false,
          extensions = {
            copilotchat = {
              enabled = true,
              convert_tools_to_functions = true,
              convert_resources_to_functions = true,
              add_mcp_prefix = false,
            },
          },
          ui = {
            window = {
              border = "single",
            },
          },
        })
      end,
    },
    {
      "ishiooon/codex.nvim",
      dependencies = {
        "folke/snacks.nvim",
      },
      enabled = function()
        return vim.fn.executable("codex") == 1
      end,
      cmd = {
        "Codex",
        "CodexFocus",
        "CodexSend",
        "CodexTreeAdd",
      },
      config = function()
        local notify_path = vim.fn.stdpath("state") .. "/codex.nvim/notify.jsonl"

        require("codex").setup({
          terminal_cmd = vim.fn.exepath("codex"),
          env = {
            ENABLE_IDE_INTEGRATION = "true",
            CODEX_NVIM_NOTIFY_PATH = notify_path,
          },
          status_indicator = {
            cli_notify_path = notify_path,
          },
        })
      end,
    },
    { import = "plugins" },
  },
  defaults = {
    lazy = true,
    version = false,
  },
  install = { colorscheme = { "catppuccin", "habamax" } },
  checker = {
    enabled = false,
    notify = false,
  },
  performance = {
    rtp = {
      disabled_plugins = {
        "gzip",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
})
