-- Enable the snacks.nvim image module (was disabled). Renders real inline
-- images via the kitty graphics protocol when nvim runs inside kitty.
--   • open an image file (png/jpg/gif/webp/...) → it renders
--   • images in markdown/html/etc. render inline
--   • <leader>img or :lua Snacks.image.hover() previews the image under cursor
return {
  {
    "folke/snacks.nvim",
    opts = {
      image = {
        enabled = true,
        doc = { inline = true, float = true },
      },
    },
  },
}
