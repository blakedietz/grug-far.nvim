local MiniTest = require('mini.test')
local helpers = require('grug-far/test/helpers')

---@type NeovimChild
local child = MiniTest.new_child_neovim()

local T = MiniTest.new_set({
  hooks = {
    pre_case = function()
      helpers.initChildNeovim(child)
    end,
    -- Stop once all test cases are finished
    post_once = child.stop,
  },
})

T['can search for some string'] = function()
  helpers.writeTestFiles({
    { filename = 'file1', content = [[ grug walks ]] },
    {
      filename = 'file2',
      content = [[ 
      grug talks and grug drinks
      then grug thinks
    ]],
    },
  })

  helpers.childRunGrugFar(child, {
    prefills = { search = 'grug' },
  })

  helpers.childWaitForFinishedStatus(child)

  helpers.childExpectScreenshot(child)
  helpers.childExpectBufLines(child)
end

T['can search manually on insert leave'] = function()
  helpers.writeTestFiles({
    { filename = 'file1', content = [[ grug walks ]] },
    {
      filename = 'file2',
      content = [[ 
      grug talks and grug drinks
      then grug thinks
    ]],
    },
  })

  helpers.childRunGrugFar(child, {
    searchOnInsertLeave = true,
  })

  child.type_keys(50, '<esc>cc', 'walks')
  vim.uv.sleep(100)
  helpers.childExpectScreenshot(child)

  child.type_keys(50, '<esc>')
  helpers.childWaitForUIVirtualText(child, '1 matches in 1 files')
  helpers.childWaitForFinishedStatus(child)
  helpers.childExpectScreenshot(child)
end

T['reports error from rg'] = function()
  helpers.writeTestFiles({
    { filename = 'file1', content = [[ grug walks ]] },
    {
      filename = 'file2',
      content = [[ 
      grug talks and grug drinks
      then grug thinks
    ]],
    },
  })

  helpers.childRunGrugFar(child, {
    -- note: invalid regex
    prefills = { search = 'grug ([])' },
  })

  helpers.childWaitForFinishedStatus(child)

  helpers.childExpectScreenshot(child)
end

T['can search with flags'] = function()
  helpers.writeTestFiles({
    { filename = 'file1', content = [[ grug walks ]] },
    {
      filename = 'file2',
      content = [[ 
      grug talks and grug drinks
      then grug thinks
    ]],
    },
  })

  helpers.childRunGrugFar(child, {
    prefills = { search = 'GRUG', flags = '--ignore-case' },
  })

  helpers.childWaitForFinishedStatus(child)

  helpers.childExpectScreenshot(child)
  helpers.childExpectBufLines(child)
end

T['can search with particular file in paths'] = function()
  helpers.writeTestFiles({
    { filename = 'file1', content = [[ grug walks ]] },
    {
      filename = 'file2',
      content = [[ 
      grug talks and grug drinks
      then grug thinks
    ]],
    },
  })

  helpers.childRunGrugFar(child, {
    prefills = { search = 'GRUG', flags = '--ignore-case', paths = './file1' },
  })

  helpers.childWaitForFinishedStatus(child)

  helpers.childExpectScreenshot(child)
  helpers.childExpectBufLines(child)
end

T['can search with particular dir in paths'] = function()
  helpers.writeTestFiles({
    { filename = 'file1', content = [[ grug walks ]] },
    {
      filename = 'file2',
      content = [[ 
      grug talks and grug drinks
      then grug thinks
    ]],
    },
  })

  helpers.childRunGrugFar(child, {
    prefills = { search = 'GRUG', flags = '--ignore-case', paths = '.' },
  })

  helpers.childWaitForFinishedStatus(child)

  helpers.childExpectScreenshot(child)
  helpers.childExpectBufLines(child)
end

T['can search with particular file in flags'] = function()
  helpers.writeTestFiles({
    { filename = 'file1', content = [[ grug walks ]] },
    {
      filename = 'file2',
      content = [[ 
      grug talks and grug drinks
      then grug thinks
    ]],
    },
  })

  helpers.childRunGrugFar(child, {
    prefills = { search = 'GRUG', flags = './file1 --ignore-case' },
  })

  helpers.childWaitForFinishedStatus(child)

  helpers.childExpectScreenshot(child)
  helpers.childExpectBufLines(child)
end

T['can search with file filter'] = function()
  helpers.writeTestFiles({
    { filename = 'file1.txt', content = [[ grug walks ]] },
    {
      filename = 'file2.doc',
      content = [[ 
      grug talks and grug drinks
      then grug thinks
    ]],
    },
  })

  helpers.childRunGrugFar(child, {
    prefills = { search = 'grug', filesFilter = '**/*.txt' },
  })

  helpers.childWaitForFinishedStatus(child)

  helpers.childExpectScreenshot(child)
  helpers.childExpectBufLines(child)
end

T['can search with replace string'] = function()
  helpers.writeTestFiles({
    { filename = 'file1.txt', content = [[ grug walks ]] },
    {
      filename = 'file2.doc',
      content = [[ 
      grug talks and grug drinks
      then grug thinks
    ]],
    },
  })

  helpers.childRunGrugFar(child, {
    prefills = { search = 'grug', replacement = 'curly' },
  })

  helpers.childWaitForFinishedStatus(child)

  helpers.childExpectScreenshot(child)
  helpers.childExpectBufLines(child)
end

T['can search with no matches'] = function()
  helpers.writeTestFiles({
    { filename = 'file1.txt', content = [[ grug walks ]] },
    {
      filename = 'file2.doc',
      content = [[ 
      grug talks and grug drinks
      then grug thinks
    ]],
    },
  })

  helpers.childRunGrugFar(child, {
    prefills = { search = 'george' },
  })

  helpers.childWaitForFinishedStatus(child)

  helpers.childExpectScreenshot(child)
  helpers.childExpectBufLines(child)
end

T['can search for some string with many matches'] = function()
  local files = {}
  for i = 1, 100 do
    table.insert(files, {
      filename = 'file_' .. i,
      content = [[
        grug walks many steps
        grug talks and grug drinks
        then grug thinks
      ]],
    })
  end
  helpers.writeTestFiles(files)

  helpers.childRunGrugFar(child, {
    prefills = { search = 'grug' },
  })

  helpers.childWaitForFinishedStatus(child)

  helpers.childExpectScreenshot(child)
  helpers.childExpectBufLines(child)
end

T['can search and edit search'] = function()
  helpers.writeTestFiles({
    { filename = 'file1.txt', content = [[ grug walks ]] },
    {
      filename = 'file2.doc',
      content = [[ 
      grug talks and grug drinks
      then grug thinks
    ]],
    },
  })

  helpers.childRunGrugFar(child, {
    prefills = { search = 'grug' },
  })

  helpers.childWaitForFinishedStatus(child)

  child.type_keys(50, '<esc>cc', 'walks')
  helpers.childWaitForUIVirtualText(child, '1 matches in 1 files')
  helpers.childWaitForFinishedStatus(child)

  helpers.childExpectScreenshot(child)
  helpers.childExpectBufLines(child)
end

T['can search for visual selection inside one line'] = function()
  helpers.writeTestFiles({
    { filename = 'file1', content = [[ grug walks ]] },
    {
      filename = 'file2',
      content = [[ 
      grug talks and grug drinks
      then grug thinks
      something else
    ]],
    },
  })

  helpers.cdTempTestDir(child)
  child.cmd(':e file2')
  child.type_keys(50, 'jj', 'vee', '<esc>:<C-u>lua GrugFar.with_visual_selection()<CR>')

  helpers.childWaitForFinishedStatus(child)

  helpers.childExpectScreenshot(child)
end

T['searches full line visual selection'] = function()
  helpers.writeTestFiles({
    { filename = 'file1', content = [[ grug walks ]] },
    {
      filename = 'file2',
      content = [[ 
      grug talks and grug drinks
      then grug thinks
      something else
    ]],
    },
  })

  helpers.cdTempTestDir(child)
  child.cmd(':e file2')
  child.type_keys(100, 'j', '0v$', '<esc>:lua GrugFar.with_visual_selection()<CR>')

  helpers.childWaitForFinishedStatus(child)

  helpers.childExpectScreenshot(child)
end

T['searches first line of multiline visual selection'] = function()
  helpers.writeTestFiles({
    { filename = 'file1', content = [[ grug walks ]] },
    {
      filename = 'file2',
      content = [[ 
      grug talks and grug drinks
      then grug thinks
      something else
    ]],
    },
  })

  helpers.cdTempTestDir(child)
  child.cmd(':e file2')
  child.type_keys(50, 'j', 'wwwvjj', '<esc>:<C-u>lua GrugFar.with_visual_selection()<CR>')

  helpers.childWaitForFinishedStatus(child)

  helpers.childExpectScreenshot(child)
end

return T
