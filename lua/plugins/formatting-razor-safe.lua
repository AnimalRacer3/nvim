return {
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        -- C# formatting: pick ONE (whichever you have installed)
        cs = { "csharpier" }, -- if you install csharpier as a dotnet tool
        -- or: cs = { "dotnet_format" }, -- if you prefer dotnet format

        -- Razor: keep empty so Conform doesn't try to format it
        razor = {},
      },
    },
  },
}
