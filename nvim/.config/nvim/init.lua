---@diagnostic disable: undefined-global, duplicate-set-field
local providers = { "python3", "node", "perl", "ruby" }
for _, provider in ipairs(providers) do
  vim.g["loaded_" .. provider .. "_provider"] = 0
end

vim.cmd([[
  set nosmd noswf nowb ph=10 scl=yes noru ch=0 fcs=eob:\  sw=2 scs spr sb nu nowrap udf
  \ ic et shm+=I ts=2 nosc ls=0 stal=0 so=7 ve=block rnu gcr+=t:ver25-TermCursor mouse=
]])

vim.schedule(function() vim.o.clipboard = "unnamedplus" end)

local tokyopath = vim.fn.stdpath("data") .. "/lazy/tokyonight.nvim"
local tokyorepo = "https://github.com/folke/tokyonight.nvim.git"
if not vim.uv.fs_stat(tokyopath) then vim.cmd("!git clone --filter=blob:none " .. tokyorepo .. " " .. tokyopath) end
vim.opt.rtp:prepend(tokyopath)

require("tokyonight").setup({
  transparent = true,
  terminal_colors = false,
  styles = {
    sidebars = "transparent",
    floats = "transparent",
    comments = { italic = false },
    keywords = { italic = false },
  },
  style = "night",
  on_highlights = function(hl, c)
    hl.Normal = { bg = "black", fg = c.fg }
    hl.TermCursor = { bg = c.red }
  end,
})
require("tokyonight").load()

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
local lazyrepo = "https://github.com/folke/lazy.nvim.git"
local INSTALL = false
if not vim.uv.fs_stat(lazypath) then
  vim.cmd("!git clone --filter=blob:none " .. lazyrepo .. " " .. lazypath)
  INSTALL = true
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  lockfile = vim.fn.stdpath("state") .. "/lazy-lock.json",
  rocks = { enabled = false },
  install = { colorscheme = { "tokyonight" } },
  ui = { backdrop = 30, icons = { loaded = "", not_loaded = "", list = { "", "", "", "" } } },
  change_detection = { enabled = false },
  default = { lazy = true },
  spec = {

    "folke/tokyonight.nvim",

    {
      "folke/noice.nvim",
      event = "VeryLazy",
      dependencies = { "MunifTanjim/nui.nvim" },
      keys = { { "<space>m", "<cmd>NoiceAll<cr>" } },
      opts = {
        lsp = {
          progress = { enabled = false },
          signature = { enabled = false },
          override = {
            ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
            ["vim.lsp.util.stylize_markdown"] = true,
            ["cmp.entry.get_documentation"] = true,
          },
        },
        cmdline = {
          format = {
            cmdline = { icon = "", conceal = true },
            search_down = { icon = " /", conceal = true },
            search_up = { icon = " ?", conceal = true },
            filter = false,
            lua = false,
            help = false,
            input = { view = "cmdline_popup" },
          },
        },
        views = {
          cmdline_popup = {
            border = "none",
            position = { row = 0, col = 0 },
            size = { width = "auto", height = 1 },
          },
          popupmenu = {
            border = { style = "none", padding = { 0, 1 } },
            position = { row = 1, col = 0 },
            scrollbar = false,
            size = { width = 60, max_height = 10 },
          },
          split = { enter = true, scrollbar = false },
        },
        routes = {
          { filter = { event = "msg_show", any = { { find = "written" } } }, view = "mini" },
          { filter = { event = "msg_show", min_height = 4 }, view = "split" },
        },
      },
    },

    {
      "stevearc/oil.nvim",
      event = { "VimEnter */*,.*", "BufNew */*,.*" },
      cmd = "Oil",
      keys = { { "-", "<cmd>Oil<cr>" }, { "_", "<cmd>Oil .<cr>" } },
      opts = {
        keymaps = { ["`"] = false, ["q"] = { "actions.close", mode = "n" } },
        view_options = { show_hidden = true },
        delete_to_trash = true,
        skip_confirm_for_simple_edits = true,
        float = { border = "single" },
        confirmation = { border = "single" },
        progress = { border = "single" },
        ssh = { border = "single" },
        keymaps_help = { border = "single" },
      },
    },

    {
      "folke/flash.nvim",
      event = "VeryLazy",
      keys = {
        { "<space>n", mode = { "n", "x", "o" }, function() require("flash").jump() end },
        { "r", mode = "o", function() require("flash").remote() end },
      },
      opts = { modes = { char = { keys = {} } } },
    },

    { "nvim-mini/mini.pairs", event = "VeryLazy", opts = {} },

    {
      "nvim-mini/mini.surround",
      event = "VeryLazy",
      opts = {
        mappings = { add = "za", delete = "zd", find = "zf", find_left = "zF", highlight = "zh", replace = "zr" },
      },
    },

    { "nvim-mini/mini.ai", event = "VeryLazy", opts = {} },

    { "nvim-mini/mini.splitjoin", event = "VeryLazy", opts = {} },

    { "nvim-mini/mini-git", main = "mini.git", event = "VeryLazy", opts = {} },

    {
      "lewis6991/gitsigns.nvim",
      event = "VeryLazy",
      keys = {
        {
          "tt",
          function()
            if not vim.wo.diff then require("gitsigns").diffthis("", { split = "rightbelow" }) end
            for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
              if vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(w)):find("^gitsigns://") then
                return vim.schedule(function() vim.api.nvim_win_close(w, true) end)
              end
            end
          end,
        },
        { "<space>k", function() require("gitsigns").nav_hunk("prev") end },
        { "<space>j", function() require("gitsigns").nav_hunk("next") end },
        {
          "gs",
          function()
            if vim.fn.mode() == "n" then
              require("gitsigns").stage_hunk()
            else
              require("gitsigns").stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
            end
          end,
          mode = { "n", "v" },
        },
        {
          "gh",
          function()
            if vim.fn.mode() == "n" then
              require("gitsigns").reset_hunk()
            else
              require("gitsigns").reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
            end
          end,
          mode = { "n", "v" },
        },
      },
      opts = {},
    },

    {
      "willothy/flatten.nvim",
      lazy = false,
      opts = {
        window = { open = "alternate" },
        hooks = {
          pre_open = function() require("snacks").terminal.toggle() end,
        },
      },
    },

    {
      "folke/snacks.nvim",
      priority = 2000,
      lazy = false,
      dependencies = { { "folke/persistence.nvim", event = "BufReadPre", opts = {} } },
      keys = {
        { "<space>.", function() Snacks.scratch.open() end },
        { "<space>S", function() Snacks.scratch.select() end },

        { "<space>;", function() Snacks.picker.buffers() end },
        { "<space>,", function() Snacks.picker.buffers({ filter = { cwd = Snacks.git.get_root() } }) end },
        { "<space>q", function() Snacks.bufdelete.delete({ force = true }) end },
        { "<space>o", function() Snacks.bufdelete.other({ force = true }) end },
        { "<space>Q", function() Snacks.bufdelete.all({ force = true }) end },

        { "<space>/", function() Snacks.picker.grep({ dirs = { Snacks.git.get_root() } }) end },
        { "<space>?", function() Snacks.picker.grep_buffers() end },

        { "<space>e", function() Snacks.picker.explorer({ cwd = Snacks.git.get_root() }) end },

        { "<space>x", function() Snacks.picker.diagnostics_buffer() end },
        { "<space>X", function() Snacks.picker.diagnostics({ filter = { cwd = Snacks.git.get_root() } }) end },

        { "<space>f", function() Snacks.picker.files() end },
        { "ff", function() Snacks.picker.files({ cwd = Snacks.git.get_root() }) end },
        { "<space>c", function() Snacks.picker.files({ cwd = "~/src/zx" }) end },

        { "<space>v", function() Snacks.picker.projects() end },
        { "<space>E", function() Snacks.picker.project_init() end },
        { "<space>C", function() Snacks.picker.zoxide() end },

        {
          "<space>g",
          function()
            if Snacks.git.get_root() then
              Snacks.lazygit({ cwd = Snacks.git.get_root() })
            else
              vim.notify("Not in a Git repository", vim.log.levels.ERROR)
            end
          end,
        },

        { "<space>s", function() Snacks.picker.pickers() end },

        { "<space>r", function() Snacks.picker.recent() end },
        { "<space>h", function() Snacks.picker.help() end },
        { "<space>i", function() Snacks.picker.icons() end },
        { "<space>u", function() Snacks.picker.undo() end },
        { "<space>y", function() Snacks.picker.spelling() end },

        { mode = { "n", "t" }, "`", function() Snacks.terminal.toggle() end },
      },
      opts = {
        bigfile = { enabled = true },
        quickfile = { enabled = true },
        statuscolumn = { enabled = true },
        input = { icon = "", prompt_pos = "left", win = { border = "none", width = vim.o.co, row = 0, col = 0 } },
        terminal = { win = { wo = { winbar = "" } } },
        lazygit = { win = { keys = { term_normal = { "<esc>" } } } },
        scratch = { win = { position = "top" } },
        picker = {
          prompt = "",
          sources = {
            files = { hidden = true },
            grep = { hidden = true },
            explorer = {
              hidden = true,
              auto_close = true,
              win = {
                input = {
                  keys = {
                    ["<S-Tab>"] = { "select_and_prev", mode = { "i", "n" } },
                    ["<Tab>"] = { "select_and_next", mode = { "i", "n" } },
                  },
                },
                list = {
                  keys = {
                    ["o"] = "explorer_add",
                    ["<S-Tab>"] = { "select_and_prev", mode = { "n", "x" } },
                    ["<Tab>"] = { "select_and_next", mode = { "n", "x" } },
                  },
                },
              },
            },
            projects = {
              dev = "~/src",
              recent = false,
              win = {
                input = {
                  keys = {
                    ["<c-x>"] = { "project_remove", mode = { "i", "n" } },
                    ["<c-n>"] = { "project_init", mode = { "i", "n" } },
                  },
                },
                list = { keys = { ["dd"] = "project_remove", ["<n>"] = "project_init" } },
              },
              actions = {
                project_remove = function(picker, item)
                  if not item or not item.file then return end
                  local path = item.file
                  if picker._project_removing then return end
                  picker._project_removing = true
                  local cwd = vim.uv.cwd()
                  if cwd and cwd:match("^" .. vim.pesc(path)) then vim.cmd("cd ~/src/") end
                  local ok, err = require("snacks.explorer.actions").trash(path)
                  if ok then
                    if cwd == path then Snacks.bufdelete.all({ force = true }) end
                    picker:refresh()
                    vim.notify("Project deleted: " .. path)
                  else
                    vim.notify("Failed to delete project:\n" .. err, vim.log.levels.ERROR)
                  end
                  picker._project_removing = false
                end,
                project_init = function(picker)
                  picker:close()
                  Snacks.picker.project_init()
                end,
              },
            },
            project_init = {
              languages = {
                _ = "",
                c = "mkdir src && touch src/main.c",
                cpp = "mkdir src && touch src/main.cpp",
                go = "touch main.go && ",
                java = "mkdir src && touch src/main.java",
                python = "uv init",
                rust = "cargo init",
                zig = "zig init",
              },
              finder = function(opts)
                local ret = {}
                for key, _ in pairs(opts.languages) do
                  table.insert(ret, { text = key })
                end
                return ret
              end,
              format = "text",
              layout = "dropdown",
              confirm = function(picker, item)
                picker:close()
                if not item then return end
                local ok, name = pcall(vim.fn.input, "New Project Name: ")
                if not ok or vim.trim(name) == "" then
                  vim.notify("Empty Project Name", vim.log.levels.WARN)
                  return
                end
                local cwd = vim.fn.expand("~/src/" .. name)
                vim.fn.mkdir(cwd, "p")
                local cmd = picker.opts.languages[item.text]
                if item.text == "go" then cmd = cmd .. "go mod init " .. name end
                local function find_main_file(dir)
                  local files = vim.fn.glob(dir .. "/**/main.*", false, true, true)
                  if #files > 0 then return files[1] end
                  return nil
                end
                Snacks.picker.util.cmd("git init && " .. cmd, function(_, code)
                  if code == 0 then
                    vim.notify("project created successfully", vim.log.levels.INFO)
                    vim.fn.chdir(cwd)
                    local main = find_main_file(cwd)
                    if main then vim.cmd("edit " .. main) end
                  else
                    vim.notify("Error creating project", vim.log.levels.ERROR)
                  end
                end, { cwd = cwd })
              end,
            },
            zoxide = {
              win = {
                input = { keys = { ["<c-x>"] = { "zoxide_remove", mode = { "i", "n" } } } },
                list = { keys = { ["dd"] = "zoxide_remove" } },
              },
              actions = {
                zoxide_remove = function(picker, item)
                  if not item or not item.file then return end
                  local path = item.file
                  if picker._zoxide_removing then return end
                  picker._zoxide_removing = true
                  Snacks.picker.util.cmd({ "zoxide", "remove", path }, function()
                    picker._zoxide_removing = false
                    picker:refresh()
                  end)
                end,
              },
            },
          },
          win = {
            input = {
              keys = {
                ["<Tab>"] = { "list_down", mode = { "i", "n" } },
                ["<S-Tab>"] = { "list_up", mode = { "i", "n" } },
              },
            },
            list = { keys = { ["<Tab>"] = "list_down", ["<S-Tab>"] = "list_up" } },
          },
          previewers = { diff = { style = "syntax", wo = { wrap = false } } },
          layouts = {
            default = {
              cycle = true,
              layout = {
                width = 0.8,
                min_width = 120,
                height = 0.8,
                box = "horizontal",
                {
                  box = "vertical",
                  border = "single",
                  { win = "input", height = 1, border = "bottom" },
                  { win = "list" },
                },
                { win = "preview", border = "single", width = 0.5 },
              },
            },
            dropdown = {
              cycle = true,
              preview = false,
              layout = {
                width = 70,
                min_width = 70,
                height = 0.8,
                box = "vertical",
                {
                  box = "vertical",
                  border = "single",
                  { win = "input", height = 1, border = "bottom" },
                  { win = "list" },
                },
              },
            },
            select = {
              cycle = true,
              preview = false,
              layout = {
                width = 70,
                min_width = 70,
                height = 0.8,
                box = "vertical",
                {
                  box = "vertical",
                  border = "single",
                  { win = "input", height = 1, border = "bottom" },
                  { win = "list" },
                },
              },
            },
            vscode = {
              cycle = true,
              preview = false,
              layout = {
                width = 70,
                min_width = 70,
                height = 0.8,
                box = "vertical",
                {
                  box = "vertical",
                  border = "single",
                  { win = "input", height = 1, border = "bottom" },
                  { win = "list" },
                },
              },
            },
            vertical = {
              cycle = true,
              preview = false,
              layout = {
                width = 70,
                min_width = 70,
                height = 0.8,
                box = "vertical",
                {
                  box = "vertical",
                  border = "single",
                  { win = "input", height = 1, border = "bottom" },
                  { win = "list" },
                },
              },
            },
            sidebar = {
              cycle = true,
              preview = "main",
              layout = {
                width = 40,
                min_width = 40,
                height = 0,
                position = "right",
                box = "vertical",
                { win = "list" },
                { win = "input", height = 1 },
                { win = "preview" },
              },
            },
            telescope = {
              cycle = true,
              reverse = false,
              layout = {
                width = 0.8,
                min_width = 120,
                height = 0.8,
                box = "horizontal",
                {
                  box = "vertical",
                  border = "single",
                  { win = "input", height = 1, border = "bottom" },
                  { win = "list" },
                },
                { win = "preview", title = "", border = "single", width = 0.5 },
              },
            },
            ivy = {
              cycle = true,
              layout = {
                box = "vertical",
                height = 0.4,
                position = "bottom",
                { win = "input", height = 1 },
                { box = "horizontal", { win = "list" }, { win = "preview", width = 0.6 } },
              },
            },
            ivy_split = {
              preview = "main",
              cycle = true,
              layout = {
                width = 0,
                height = 0.4,
                position = "bottom",
                box = "vertical",
                { win = "input", height = 1 },
                { win = "list" },
                { win = "preview" },
              },
            },
          },
        },
      },
      config = function(_, opts)
        Snacks.terminal.tid = function(cmd, opt)
          return vim.inspect({
            cmd = type(cmd) == "table" and cmd or { cmd },
            env = opt.env,
            count = opt.count or vim.v.count1,
          })
        end
        Snacks.setup(opts)
      end,
    },

    {
      "CRAG666/code_runner.nvim",
      cmd = { "RunCode", "RunFile", "RunProject", "RunClose", "CRFiletype", "CRProjects" },
      keys = { {
        "<space>b",
        function() require("code_runner").run_code() end,
      } },
      config = function()
        local function run(args)
          return function()
            local cwd = vim.uv.cwd()
            local root_file = cwd .. "/" .. args.root_marker
            if vim.fn.filereadable(root_file) == 1 then
              require("code_runner.commands").run_from_fn(args.project_cmd)
            else
              require("code_runner.commands").run_from_fn(args.file_cmd)
            end
          end
        end
        require("code_runner").setup({
          startinsert = true,
          filetype = {
            c = {
              "cd $dir &&",
              "clang $fileName -o $fileNameWithoutExt &&",
              "$dir/$fileNameWithoutExt &&",
              "rm $dir/$fileNameWithoutExt",
            },
            cpp = {
              "cd $dir &&",
              "clang++ $fileName -o $fileNameWithoutExt &&",
              "$dir/$fileNameWithoutExt &&",
              "rm $dir/$fileNameWithoutExt",
            },
            java = "java $fileNameWithoutExt",
            python = "uv run",
            go = run({
              root_marker = "go.mod",
              project_cmd = { "go build -o target &&", "$dir/target &&", "rm $dir/target" },
              file_cmd = "go run $filename",
            }),
            rust = run({
              root_marker = "Cargo.toml",
              project_cmd = "cargo run $end",
              file_cmd = { "rustc $fileName -o target &&", "$dir/target &&", "rm $dir/target" },
            }),
            zig = run({
              root_marker = "build.zig",
              project_cmd = "zig build run $end",
              file_cmd = "zig run $fileName",
            }),
          },
          before_run_filetype = function() vim.cmd.update() end,
        })
      end,
    },

    {
      "neovim/nvim-lspconfig",
      init = function()
        vim.lsp.enable({ "lua_ls", "pyright", "clangd", "gopls", "jdtls", "rust_analyzer", "ts_ls", "zls" })
        vim.lsp.config(
          "lua_ls",
          { settings = { Lua = { workspace = { library = vim.api.nvim_get_runtime_file("", true) } } } }
        )
        vim.lsp.config("pyright", { settings = { python = { pythonPath = ".venv/bin/python" } } })
      end,
    },

    {
      "stevearc/conform.nvim",
      event = { "BufWritePost" },
      cmd = { "ConformInfo" },
      opts = {
        format_after_save = { lsp_format = "fallback" },
        formatters_by_ft = {
          c = { "clang_format" },
          cpp = { "clang_format" },
          go = { "gofumpt" },
          java = { "google-java-format" },
          json = { "jq" },
          lua = { "stylua" },
          nix = { "alejandra", "injected" },
          python = { "ruff", "ruff_fix", "ruff_format", "ruff_organize_imports" },
          rust = { "rustfmt" },
          zig = { "zigfmt" },
          ["_"] = { "trim_whitespace" },
        },
        formatters = {
          stylua = {
            prepend_args = {
              "--indent-type",
              "Spaces",
              "--indent-width",
              "2",
              "--column-width",
              "120",
              "--collapse-simple-statement",
              "Always",
            },
          },
          clang_format = { prepend_args = { "--style=Google" } },
        },
      },
    },

    {
      "Saghen/blink.cmp",
      version = "*",
      dependencies = { "rafamadriz/friendly-snippets" },
      event = "InsertEnter",
      opts = {
        appearance = { nerd_font_variant = "normal" },
        keymap = {
          preset = "default",
          ["<Tab>"] = { "select_next", "snippet_forward", "fallback" },
          ["<S-Tab>"] = { "select_prev", "snippet_backward", "fallback" },
          ["<CR>"] = {
            function(cmp)
              if cmp.is_menu_visible() then
                if cmp.get_selected_item() then
                  return cmp.accept()
                else
                  return cmp.cancel()
                end
              end
            end,
            "fallback",
          },
        },
        completion = {
          menu = {
            draw = { columns = { { "label", gap = 1 }, { "kind_icon", "kind" } } },
            winhighlight = "Normal:Pmenu",
          },
          list = { selection = { preselect = false } },
          documentation = {
            auto_show = true,
            auto_show_delay_ms = 0,
            window = {
              winhighlight = "Normal:Pmenu",
              scrollbar = false,
            },
          },
        },
        cmdline = { enabled = false },
        sources = {
          default = { "lsp", "path", "snippets", "buffer" },
          providers = { lsp = { fallbacks = {} } },
        },
        signature = { enabled = true, window = { winhighlight = "Normal:Pmenu" } },
      },
      init = function() vim.lsp.config("*", { capabilities = require("blink.cmp").get_lsp_capabilities() }) end,
    },
  },
})

vim.keymap.set("n", "<space>R", "<cmd>cd ~/src/ | restart +qall!<cr>")
vim.keymap.set("n", "<space><space>", "<cmd>update<cr>")
vim.keymap.set("n", "<Tab>", "<C-w><C-w>")
vim.keymap.set("n", "<A-j>", "<cmd>execute 'move .+' . v:count1<cr>==")
vim.keymap.set("n", "<A-k>", "<cmd>execute 'move .-' . (v:count1 + 1)<cr>==")
vim.keymap.set("i", "<A-j>", "<esc><cmd>m .+1<cr>==gi")
vim.keymap.set("i", "<A-k>", "<esc><cmd>m .-2<cr>==gi")
vim.keymap.set("v", "<A-j>", ":<C-u>execute \"'<,'>move '>+\" . v:count1<cr>gv=gv")
vim.keymap.set("v", "<A-k>", ":<C-u>execute \"'<,'>move '<-\" . (v:count1 + 1)<cr>gv=gv")
vim.keymap.set("n", "H", "<cmd>bprevious<cr>")
vim.keymap.set("n", "L", "<cmd>bnext<cr>")
vim.keymap.set("n", "n", "'Nn'[v:searchforward].'zv'", { expr = true })
vim.keymap.set("x", "n", "'Nn'[v:searchforward]", { expr = true })
vim.keymap.set("o", "n", "'Nn'[v:searchforward]", { expr = true })
vim.keymap.set("n", "N", "'nN'[v:searchforward].'zv'", { expr = true })
vim.keymap.set("x", "N", "'nN'[v:searchforward]", { expr = true })
vim.keymap.set("o", "N", "'nN'[v:searchforward]", { expr = true })
vim.keymap.set({ "i", "n", "s" }, "<esc>", "<cmd>noh<CR><esc>")
vim.keymap.set("i", "<Tab>", function()
  local col = vim.fn.col(".")
  local line = vim.fn.getline(".")
  local char = line:sub(col, col)
  if char:match("[%(%)%{%}%[%]<>\"']") then
    return "<Right>"
  else
    return "<Tab>"
  end
end, { expr = true, silent = true })
vim.keymap.set("i", "<S-Tab>", function()
  local col = vim.fn.col(".")
  local line = vim.fn.getline(".")
  local char = line:sub(col - 1, col - 1)
  if char:match("[%(%)%{%}%[%]<>\"']") then
    return "<Left>"
  else
    return "<S-Tab>"
  end
end, { expr = true, silent = true })

vim.api.nvim_create_autocmd("TextYankPost", {
  group = vim.api.nvim_create_augroup("highlight_yank", { clear = true }),
  callback = function() vim.hl.on_yank() end,
})

vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("no_auto_comment", { clear = true }),
  command = "setlocal formatoptions-=cro",
})

vim.api.nvim_create_autocmd("BufReadPost", {
  group = vim.api.nvim_create_augroup("restore_cursor", { clear = true }),
  callback = function(event)
    local exclude = { "gitcommit" }
    local buf = event.buf
    if vim.tbl_contains(exclude, vim.bo[buf].filetype) or vim.b[buf].last_loc then return end
    vim.b[buf].last_loc = true
    local mark = vim.api.nvim_buf_get_mark(buf, '"')
    local lcount = vim.api.nvim_buf_line_count(buf)
    if mark[1] > 0 and mark[1] <= lcount then pcall(vim.api.nvim_win_set_cursor, 0, mark) end
  end,
})

vim.api.nvim_create_autocmd("BufWritePre", {
  group = vim.api.nvim_create_augroup("save_mkdir", { clear = true }),
  callback = function(event)
    if event.match:match("^%w%w+:[\\/][\\/]") then return end
    local file = vim.uv.fs_realpath(event.match) or event.match
    vim.fn.mkdir(vim.fn.fnamemodify(file, ":p:h"), "p")
  end,
})

vim.api.nvim_create_autocmd({ "BufUnload", "BufDelete" }, {
  group = vim.api.nvim_create_augroup("lsp_unload", { clear = true }),
  callback = function()
    vim.defer_fn(function()
      for _, client in pairs(vim.lsp.get_clients()) do
        local is_attached = false
        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
          if vim.lsp.buf_is_attached(buf, client.id) then
            is_attached = true
            break
          end
        end
        if not is_attached then client:stop() end
      end
    end, 100)
  end,
})

vim.api.nvim_create_autocmd({ "TermRequest" }, {
  group = vim.api.nvim_create_augroup("term_osc7", { clear = true }),
  callback = function(ev)
    local val, n = string.gsub(ev.data.sequence, "\027]7;file://[^/]*/", "")
    if n > 0 then
      local dir = val
      if vim.fn.isdirectory(dir) == 0 then
        vim.notify("invalid dir: " .. dir)
        return
      end
      vim.b[ev.buf].osc7_dir = dir
      if vim.api.nvim_get_current_buf() == ev.buf then vim.cmd.cd(dir) end
    end
  end,
})

vim.api.nvim_create_autocmd({ "TermEnter" }, {
  group = vim.api.nvim_create_augroup("term_cwd_sync", { clear = true }),
  callback = function()
    local pid = vim.b.terminal_job_pid
    if pid then
      local proc = vim.api.nvim_get_proc(pid)
      if proc then
        local shell = proc.name
        local pids = #(vim.api.nvim_get_proc_children(pid) or {})
        if shell == "zsh" and pids == 0 and vim.b.osc7_dir and vim.b.osc7_dir ~= vim.uv.cwd() then
          vim.api.nvim_chan_send(vim.b.terminal_job_id, "\x1b0Dicd '" .. vim.uv.cwd() .. "'\r")
        end
      end
    end
  end,
})

if INSTALL then vim.cmd("helptags ALL || restart") end
