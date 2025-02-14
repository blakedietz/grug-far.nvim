---@alias Region (Range4|Range6|TSNode)[]
---@alias LangRegions table<string, Region[]>
---@alias FileResults table<string, {ft: string, lines: ResultLine[]}>

---@class ResultLine
---@field row number row in the result buffer for this line
---@field col number col in the result buffer for this line
---@field end_col number end col in the result buffer for this line
---@field lnum number line number in the file

local M = {}

M.cache = {} ---@type table<number, table<string,{parser: vim.treesitter.LanguageTree, highlighter:vim.treesitter.highlighter, enabled:boolean}>>
local ns = vim.api.nvim_create_namespace('grug.treesitter')

local TSHighlighter = vim.treesitter.highlighter

local function wrap(name)
  return function(_, win, buf, ...)
    if not M.cache[buf] then
      return false
    end
    for _, hl in pairs(M.cache[buf] or {}) do
      if hl.enabled then
        TSHighlighter.active[buf] = hl.highlighter
        TSHighlighter[name](_, win, buf, ...)
      end
    end
    TSHighlighter.active[buf] = nil
  end
end

M.did_setup = false
function M.setup()
  if M.did_setup then
    return
  end
  M.did_setup = true

  vim.api.nvim_set_decoration_provider(ns, {
    on_win = wrap('_on_win'),
    on_line = wrap('_on_line'),
  })
end

---@param buf number
function M.clear(buf)
  for _, hl in pairs(M.cache[buf] or {}) do
    hl.highlighter:destroy()
    hl.parser:destroy()
  end
  M.cache[buf] = nil
end

---@param buf number
---@param regions LangRegions
function M.attach(buf, regions)
  M.setup()
  M.cache[buf] = M.cache[buf] or {}
  for lang in pairs(M.cache[buf]) do
    M.cache[buf][lang].enabled = regions[lang] ~= nil
  end

  for lang in pairs(regions) do
    M._attach_lang(buf, lang, regions[lang])
  end
end

---@param buf number
---@param lang string
---@param regions Region[]
function M._attach_lang(buf, lang, regions)
  lang = lang == 'markdown' and 'markdown_inline' or lang

  M.cache[buf] = M.cache[buf] or {}

  if not M.cache[buf][lang] then
    local ok, parser = pcall(vim.treesitter.get_parser, buf, lang)
    if not ok then
      return
    end
    M.cache[buf][lang] = {
      parser = parser,
      highlighter = TSHighlighter.new(parser),
    }
  end
  M.cache[buf][lang].enabled = true
  local parser = M.cache[buf][lang].parser
  ---@diagnostic disable-next-line: invisible
  parser:set_included_regions(regions)
end

return M
