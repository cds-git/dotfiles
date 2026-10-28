-- Prose settings for markdown buffers only

-- soft wrap at word boundaries, with wrapped list items keeping their indent
vim.opt_local.wrap = true
vim.opt_local.linebreak = true
vim.opt_local.breakindent = true

vim.opt_local.spell = true
-- check the words inside identifiers (StatusError = Status + Error) instead of flagging them
vim.opt_local.spelloptions:append("camel")
-- no complaints about lowercase sentence starts; notes and review comments are informal
vim.opt_local.spellcapcheck = ""

-- move by screen line on wrapped text, but keep counts (5j) on real lines
vim.keymap.set({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { buffer = true, expr = true })
vim.keymap.set({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", { buffer = true, expr = true })
