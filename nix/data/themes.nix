{
  everforest.setup = "let g:everforest_background = 'soft'";
  gruvbox-material.setup = "let g:gruvbox_material_background = 'soft'";
  kanagawa = { };
  melange = { };
  melange-light = {
    plugin = "melange";
    colorscheme = "melange";
    background = "light";
  };
  ayu-light = {
    plugin = "ayu";
    background = "light";
    lualine = "ayu_light";
  };
  iceberg-light = {
    plugin = "iceberg";
    colorscheme = "iceberg";
    background = "light";
    lualine = "iceberg_light";
  };
  onelight = {
    plugin = "onedark";
    colorscheme = "onedark";
    background = "light";
    lualine = "onelight";
    setup = "lua require('onedark').setup({ style = 'light' })";
  };
  papercolor-light = {
    plugin = "papercolor";
    colorscheme = "PaperColor";
    background = "light";
    lualine = "papercolor_light";
  };
  solarized-light = {
    plugin = "solarized";
    colorscheme = "solarized";
    background = "light";
    lualine = "solarized_light";
  };
}
