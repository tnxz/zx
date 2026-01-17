{inputs, ...}: {
  flake.modules.nixos.tools = {pkgs, ...}: {
    environment.systemPackages = with pkgs; [
      alejandra
      nil
      lua-language-server
      stylua
    ];
  };

  flake.modules.homeManager.nvim = {pkgs, ...}: let
    mkVimPlugin = name: src:
      pkgs.vimUtils.buildVimPlugin {
        pname = name;
        version = "unstable";
        inherit src;
      };
    code_runner = mkVimPlugin "code_runner.nvim" inputs.code_runner;
    ts-root = pkgs.vimPlugins.nvim-treesitter.withAllGrammars;
    ts-parsers = pkgs.symlinkJoin {
      name = "ts-parsers";
      paths = ts-root.dependencies;
    };
  in {
    programs.neovim = {
      enable = true;
      package = inputs.nvim.packages.${pkgs.stdenv.hostPlatform.system}.default;
      defaultEditor = true;
      viAlias = true;
      vimAlias = true;
      vimdiffAlias = true;
      withPython3 = false;
      withRuby = false;
      plugins = with pkgs.vimPlugins; [
        tokyonight-nvim
        lazy-nvim
        ts-root
        nvim-ts-context-commentstring
        comment-nvim
        nui-nvim
        noice-nvim
        flash-nvim
        tabout-nvim
        mini-pairs
        mini-surround
        mini-ai
        mini-splitjoin
        mini-move
        mini-git
        gitsigns-nvim
        oil-nvim
        flatten-nvim
        snacks-nvim
        code_runner
        nvim-lspconfig
        conform-nvim
        friendly-snippets
        blink-cmp
      ];
      extraLuaConfig =
        # lua
        ''
          vim.keymap.set({ "i", "n", "s" }, "<esc>", "<cmd>noh<CR><esc>")
          vim.keymap.set("n", "<space>r", "<cmd>restart<cr>")
          vim.keymap.set("n", "<left>", "<nop>")
          vim.keymap.set("n", "<right>", "<nop>")
          vim.keymap.set("n", "<up>", "<nop>")
          vim.keymap.set("n", "<down>", "<nop>")
          vim.keymap.set("n", "<tab>", "<C-w><C-w>")
          vim.keymap.set("n", "<space><space>", "<cmd>write<cr>")

          vim.cmd([[
            set nosmd noswf nowb ph=10 scl=yes noru ch=0 fcs=eob:\  sw=2 scs spr sb nu nowrap udf
            \ ic et shm+=I ts=2 nosc ls=0 stal=0 so=7 ve=block rnu gcr+=t:ver25-TermCursor mouse=
          ]])

          vim.g.clipboard = "pbcopy"

          vim.schedule(function() vim.o.clipboard = "unnamedplus" end)

          vim.api.nvim_create_autocmd("TextYankPost", {
            group = vim.api.nvim_create_augroup("highlight_yank", { clear = true }),
            callback = function() vim.highlight.on_yank() end,
          })

          vim.api.nvim_create_autocmd("BufReadPost", {
            group = vim.api.nvim_create_augroup("restore_cursor", { clear = true }),
            callback = function(event)
              local exclude = { "gitcommit" }
              local buf = event.buf
              if vim.tbl_contains(exclude, vim.bo[buf].filetype) or vim.b[buf].lazyvim_last_loc then return end
              vim.b[buf].lazyvim_last_loc = true
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

          vim.api.nvim_create_autocmd("BufEnter", {
            group = vim.api.nvim_create_augroup("setup_project_root", { clear = true }),
            callback = function(ev)
              if vim.bo[ev.buf].buftype ~= "" then return end
              local name = vim.api.nvim_buf_get_name(ev.buf)
              if name == "" or not vim.uv.fs_stat(name) then return end
              local path = vim.fn.resolve(name)
              if path == "" or path:match("/scratch/") then return end
              local root_file =
                vim.fs.find({ ".git", "Cargo.toml", "go.mod", ".venv", "flake.nix" }, { upward = true, path = path })[1]
              local root = root_file and vim.fs.dirname(root_file) or vim.fs.dirname(path)
              if root ~= vim.uv.cwd() then vim.fn.chdir(root) end
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
              local val, n = string.gsub(ev.data.sequence, "\027]7;file://[^/]*", "")
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
              local id = vim.b.terminal_job_id
              local tdir = vim.b.osc7_dir
              local cwd = vim.uv.cwd()
              if pid then
                local proc = vim.api.nvim_get_proc(pid)
                if proc then
                  local shell = proc.name
                  local pids = #(vim.api.nvim_get_proc_children(pid) or {})
                  if (shell == "zsh" or shell == "bash") and pids == 0 and tdir and tdir ~= cwd then
                    vim.api.nvim_chan_send(id, "\x1b0Di\x05\x15cd '" .. cwd .. "'\r")
                  end
                end
              end
            end,
          })

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

          require("lazy").setup({
            lockfile = vim.fn.stdpath("state") .. "/lazy-lock.json",
            rocks = { enabled = false },
            install = { missing = false, colorscheme = { "tokyonight" } },
            ui = { backdrop = 30, icons = { loaded = "", not_loaded = "", list = { "", "", "", "" } } },
            change_detection = { enabled = false, notify = false },
            default = { lazy = true },
            spec = {

              {
                dir = "${ts-root}",
                "nvim-treesitter/nvim-treesitter",
                event = { "BufReadPost", "BufNewFile", "BufWritePre", "VeryLazy" },
                config = function()
                  vim.opt.rtp:prepend("${ts-parsers}")
                  vim.api.nvim_create_autocmd("FileType", {
                    group = vim.api.nvim_create_augroup("treesitter.setup", {}),
                    callback = function(ev)
                      local buf, filetype = ev.buf, ev.match
                      local language = vim.treesitter.language.get_lang(filetype) or filetype
                      if not vim.treesitter.language.add(language) then return end
                      vim.treesitter.start(buf, language)
                      vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
                    end,
                  })
                end,
              },

              {
                dir = "${pkgs.vimPlugins.nvim-ts-context-commentstring}",
                "JoosepAlviste/nvim-ts-context-commentstring",
                event = "VeryLazy",
                opts = {},
              },

              {
                dir = "${pkgs.vimPlugins.comment-nvim}",
                "numToStr/Comment.nvim",
                event = "VeryLazy",
                opts = {
                  pre_hook = require("ts_context_commentstring.integrations.comment_nvim").create_pre_hook(),
                },
              },

              {
                dir = "${pkgs.vimPlugins.nui-nvim}",
                "MunifTanjim/nui.nvim",
              },

              {
                dir = "${pkgs.vimPlugins.noice-nvim}",
                "folke/noice.nvim",
                event = "VeryLazy",
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
                dir = "${pkgs.vimPlugins.flash-nvim}",
                "folke/flash.nvim",
                event = "VeryLazy",
                keys = {
                  {
                    "<space>,",
                    mode = { "n", "x", "o" },
                    function() require("flash").jump() end,
                  },
                  {
                    "r",
                    mode = "o",
                    function() require("flash").remote() end,
                  },
                },
                opts = { modes = { char = { keys = {} } } },
              },

              {
                dir = "${pkgs.vimPlugins.tabout-nvim}",
                "abecodes/tabout.nvim",
                event = "InsertEnter",
                opts = {},
              },

              {
                dir = "${pkgs.vimPlugins.mini-pairs}",
                "nvim-mini/mini.pairs",
                event = "VeryLazy",
                opts = {},
              },

              {
                dir = "${pkgs.vimPlugins.mini-surround}",
                "nvim-mini/mini.surround",
                event = "VeryLazy",
                opts = {
                  mappings = {
                    add = "za",
                    delete = "zd",
                    find = "zf",
                    find_left = "zF",
                    highlight = "zh",
                    replace = "zr",
                  },
                },
              },

              {
                dir = "${pkgs.vimPlugins.mini-ai}",
                "nvim-mini/mini.ai",
                event = "VeryLazy",
                opts = {},
              },

              {
                dir = "${pkgs.vimPlugins.mini-splitjoin}",
                "nvim-mini/mini.splitjoin",
                event = "VeryLazy",
                opts = {},
              },

              {
                dir = "${pkgs.vimPlugins.mini-move}",
                "nvim-mini/mini.move",
                event = "VeryLazy",
                opts = {},
              },

              {
                dir = "${pkgs.vimPlugins.mini-git}",
                "nvim-mini/mini-git",
                main = "mini.git",
                event = "VeryLazy",
                opts = {},
              },

              {
                dir = "${pkgs.vimPlugins.gitsigns-nvim}",
                "lewis6991/gitsigns.nvim",
                event = "VeryLazy",
                keys = {
                  {
                    "tt",
                    function()
                      if not vim.wo.diff then require("gitsigns").diffthis("", { split = "rightbelow" }) end
                      for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
                        local buf = vim.api.nvim_win_get_buf(win)
                        if vim.api.nvim_buf_get_name(buf):find("^gitsigns://") then
                          return vim.schedule(function() vim.api.nvim_win_close(win, true) end)
                        end
                      end
                    end,
                  },
                  {
                    "<space>k",
                    function() require("gitsigns").nav_hunk("prev") end,
                  },
                  {
                    "<space>j",
                    function() require("gitsigns").nav_hunk("next") end,
                  },
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
                dir = "${pkgs.vimPlugins.oil-nvim}",
                "stevearc/oil.nvim",
                event = { "VimEnter */*,.*", "BufNew */*,.*" },
                cmd = "Oil",
                keys = { { "-", "<cmd>Oil<cr>" }, { "_", "<cmd>Oil .<cr>" } },
                opts = {
                  keymaps = { ["`"] = false, ["q"] = { "actions.close", mode = "n" } },
                  view_options = { show_hidden = true },
                  delete_to_trash = true,
                  float = { border = "single" },
                  confirmation = { border = "single" },
                  progress = { border = "single" },
                  ssh = { border = "single" },
                  keymaps_help = { border = "single" },
                },
              },

              {
                dir = "${pkgs.vimPlugins.flatten-nvim}",
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
                dir = "${pkgs.vimPlugins.snacks-nvim}",
                "folke/snacks.nvim",
                priority = 2000,
                lazy = false,
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
                  explorer = { replace_netrw = true, trash = true },
                  terminal = { win = { wo = { winbar = "" } } },
                  lazygit = { win = { keys = { term_normal = { "<esc>" } } } },
                  scratch = { win = { position = "top" } },
                  picker = {
                    prompt = "",
                    sources = {
                      grep = { hidden = true },
                      explorer = { hidden = true, win = { list = { keys = { ["o"] = "explorer_add" } } } },
                      projects = {
                        dev = "~/zrc",
                        patterns = { "flake.nix", ".git", "_darcs", ".hg", ".bzr", ".svn", "package.json", "Makefile" },
                        recent = false,
                        win = {
                          input = { keys = { ["<c-x>"] = { "explorer_del", mode = { "i", "n" } } } },
                          list = { keys = { ["dd"] = "explorer_del" } },
                        },
                      },
                      zoxide = {
                        win = {
                          input = {
                            keys = {
                              ["<CR>"] = { { "cd", "picker_files" }, mode = { "n", "i" } },
                              ["<c-x>"] = { "zoxide_remove", mode = { "i", "n" } },
                            },
                          },
                          list = { keys = { ["<CR>"] = { "cd", "picker_files" }, ["dd"] = "zoxide_remove" } },
                        },
                        actions = {
                          zoxide_remove = function(picker, item)
                            if not item or not item.file then return end
                            local path = item.file
                            if picker._remove then return end
                            picker._remove = true
                            local cmd = { "zoxide", "remove", path }
                            Snacks.picker.util.cmd(cmd, function()
                              picker._remove = false
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
                  vim.api.nvim_create_autocmd({ "BufEnter", "TextChanged", "TextChangedI" }, {
                    group = vim.api.nvim_create_augroup("misc", { clear = true }),
                    callback = function(ev)
                      local ft = vim.bo[ev.buf].filetype
                      if vim.tbl_contains({ "man", "help", "lazy" }, ft) then
                        vim.cmd.setlocal("scl=no stc= nonu nornu")
                        return
                      end
                      if vim.bo[ev.buf].buftype ~= "" then return end
                      local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
                      if #lines == 1 and lines[1] == "" then
                        vim.cmd.setlocal("scl=no stc= nonu nornu")
                      else
                        vim.cmd.setlocal("scl=yes stc=%!v:lua.require'snacks.statuscolumn'.get() nu rnu")
                      end
                    end,
                  })
                end,
              },

              {
                dir = "${code_runner}",
                "CRAG666/code_runner.nvim",
                cmd = { "RunCode", "RunFile", "RunProject", "RunClose", "CRFiletype", "CRProjects" },
                keys = {
                  {
                    "<space>cr",
                    function() require("code_runner").run_code() end,
                  },
                },
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
                    before_run_filetype = function() vim.cmd.write() end,
                  })
                end,
              },

              {
                dir = "${pkgs.vimPlugins.nvim-lspconfig}",
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
                dir = "${pkgs.vimPlugins.conform-nvim}",
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
                    clang_format = { prepend_args = { "--style=Google" } },
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
                  },
                },
              },

              {
                dir = "${pkgs.vimPlugins.friendly-snippets}",
                "rafamadriz/friendly-snippets",
              },

              {
                dir = "${pkgs.vimPlugins.blink-cmp}",
                "Saghen/blink.cmp",
                version = "*",
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
                      window = { winhighlight = "Normal:Pmenu", scrollbar = false },
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
        '';
    };
  };
}
