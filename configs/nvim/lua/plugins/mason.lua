return {
  {
    "mason-org/mason.nvim",
    cmd = "Mason",
    opts = {},
    config = function(_, opts)
      require("mason").setup(opts)
    end,
  },
}
