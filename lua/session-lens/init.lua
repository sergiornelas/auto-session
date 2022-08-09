local Lib = require "session-lens.library"
local AutoSession = require "auto-session"
local SessionLensActions = require "session-lens.actions"

----------- Setup ----------
local SessionLens = {
  conf = {},
}

---@class DefaultConf
---@field theme_conf table telescope theme configuration
---@field previewer boolean telescope theme configuration

---@type DefaultConf
local defaultConf = {
  theme_conf = { winblend = 10, border = true },
  previewer = false,
}

-- Set default config on plugin load
SessionLens.conf = defaultConf

---Session lens setup function
---@param config DefaultConf the optional config for the setup function
function SessionLens.setup(config)
  SessionLens.conf = vim.tbl_deep_extend("force", config, SessionLens.conf)
end

local themes = require "telescope.themes"
local actions = require "telescope.actions"

---Search session
---Triggers the customized telescope picker for switching sessions
---@param custom_opts any
SessionLens.search_session = function(custom_opts)
  custom_opts = (vim.tbl_isempty(custom_opts or {}) or custom_opts == nil) and SessionLens.conf or custom_opts

  -- Use auto_session_root_dir from the Auto Session plugin
  local cwd = AutoSession.conf.auto_session_root_dir

  if custom_opts.shorten_path ~= nil then
    Lib.logger.error "`shorten_path` config is deprecated, use the new `path_display` config instead"
    if custom_opts.shorten_path then
      custom_opts.path_display = { "shorten" }
    else
      custom_opts.path_display = nil
    end

    custom_opts.shorten_path = nil
  end

  local theme_opts = themes.get_dropdown(custom_opts.theme_conf)

  -- Ignore last session dir on finder if feature is enabled
  if AutoSession.conf.auto_session_enable_last_session then
    if AutoSession.conf.auto_session_last_session_dir then
      local last_session_dir = AutoSession.conf.auto_session_last_session_dir:gsub(cwd, "")
      custom_opts["file_ignore_patterns"] = { last_session_dir }
    end
  end

  -- Use default previewer config by setting the value to nil if some sets previewer to true in the custom config.
  -- Passing in the boolean value errors out in the telescope code with the picker trying to index a boolean instead of a table.
  -- This fixes it but also allows for someone to pass in a table with the actual preview configs if they want to.
  if custom_opts.previewer ~= false and custom_opts.previewer == true then
    custom_opts["previewer"] = nil
  end

  local opts = {
    prompt_title = "Sessions",
    entry_maker = Lib.make_entry.gen_from_file(custom_opts),
    cwd = cwd,
    -- TOOD: support custom mappings?
    attach_mappings = function(_, map)
      actions.select_default:replace(SessionLensActions.source_session)
      map("i", "<c-d>", SessionLensActions.delete_session)
      return true
    end,
  }

  local find_files_conf = vim.tbl_deep_extend("force", opts, theme_opts, custom_opts or {})
  require("telescope.builtin").find_files(find_files_conf)
end

return SessionLens
