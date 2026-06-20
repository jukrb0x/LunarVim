local M = {}
local Log = require "lvim.core.log"

local function get_lang(buf)
  local filetype = vim.bo[buf].filetype
  return vim.treesitter.language.get_lang(filetype) or filetype
end

local function should_disable(opts, lang, buf)
  local disable = opts.highlight and opts.highlight.disable
  if type(disable) == "function" then
    return disable(lang, buf)
  end
  if type(disable) == "table" then
    return vim.tbl_contains(disable, lang)
  end
  return disable == true
end

local function setup_main(opts)
  local status_ok, treesitter = pcall(require, "nvim-treesitter")
  if not status_ok then
    Log:error "Failed to load nvim-treesitter"
    return
  end

  require("lvim.core.treesitter_compat").setup(opts)

  local install_dir = opts.parser_install_dir or (vim.fn.stdpath "data" .. "/site")
  treesitter.setup { install_dir = install_dir }

  local ensure_installed = opts.ensure_installed
  if type(ensure_installed) == "table" and #ensure_installed > 0 then
    treesitter.install(ensure_installed)
  end

  if opts.highlight and opts.highlight.enable then
    vim.api.nvim_create_autocmd("FileType", {
      group = vim.api.nvim_create_augroup("lvim_treesitter", { clear = true }),
      callback = function(args)
        local lang = get_lang(args.buf)
        if should_disable(opts, lang, args.buf) then
          return
        end

        pcall(vim.treesitter.start, args.buf, lang)

        if opts.indent and opts.indent.enable and not vim.tbl_contains(opts.indent.disable or {}, lang) then
          vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end
      end,
    })
  end

  if lvim.builtin.treesitter.on_config_done then
    lvim.builtin.treesitter.on_config_done(treesitter)
  end
end

function M.config()
  lvim.builtin.treesitter = {
    on_config_done = nil,

    -- A list of parser names, or "all"
    ensure_installed = { "comment", "markdown_inline", "regex" },

    -- List of parsers to ignore installing (for "all")
    ignore_install = {},

    -- A directory to install the parsers into.
    -- By default parsers are installed to either the package dir, or the "site" dir.
    -- If a custom path is used (not nil) it must be added to the runtimepath.
    parser_install_dir = nil,

    -- Install parsers synchronously (only applied to `ensure_installed`)
    sync_install = false,

    -- Automatically install missing parsers when entering buffer
    auto_install = true,

    matchup = {
      enable = false, -- mandatory, false will disable the whole extension
      -- disable = { "c", "ruby" },  -- optional, list of language that will be disabled
    },
    highlight = {
      enable = true, -- false will disable the whole extension
      additional_vim_regex_highlighting = false,
      disable = function(lang, buf)
        if vim.tbl_contains({ "latex" }, lang) then
          return true
        end

        local status_ok, big_file_detected = pcall(vim.api.nvim_buf_get_var, buf, "bigfile_disable_treesitter")
        return status_ok and big_file_detected
      end,
    },
    context_commentstring = {
      enable = true,
      enable_autocmd = false,
      config = {
        -- Languages that have a single comment style
        typescript = "// %s",
        css = "/* %s */",
        scss = "/* %s */",
        html = "<!-- %s -->",
        svelte = "<!-- %s -->",
        vue = "<!-- %s -->",
        json = "",
      },
    },
    indent = { enable = true, disable = { "yaml", "python" } },
    autotag = { enable = false },
    textobjects = {
      swap = {
        enable = false,
        -- swap_next = textobj_swap_keymaps,
      },
      -- move = textobj_move_keymaps,
      select = {
        enable = false,
        -- keymaps = textobj_sel_keymaps,
      },
    },
    textsubjects = {
      enable = false,
      keymaps = { ["."] = "textsubjects-smart", [";"] = "textsubjects-big" },
    },
    playground = {
      enable = false,
      disable = {},
      updatetime = 25, -- Debounced time for highlighting nodes in the playground from source code
      persist_queries = false, -- Whether the query persists across vim sessions
      keybindings = {
        toggle_query_editor = "o",
        toggle_hl_groups = "i",
        toggle_injected_languages = "t",
        toggle_anonymous_nodes = "a",
        toggle_language_display = "I",
        focus_language = "f",
        unfocus_language = "F",
        update = "R",
        goto_node = "<cr>",
        show_help = "?",
      },
    },
    rainbow = {
      enable = false,
      extended_mode = true, -- Highlight also non-parentheses delimiters, boolean or table: lang -> boolean
      max_file_lines = 1000, -- Do not enable for files with more than 1000 lines, int
    },
  }
end

function M.setup()
  local opts = vim.deepcopy(lvim.builtin.treesitter)
  setup_main(opts)
end

return M
