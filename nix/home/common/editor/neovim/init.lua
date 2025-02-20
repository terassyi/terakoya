local opts = {
	number = true,
	encofing = "utf-8",
	shell = "fish",
}

for k, v in pairs(opts) do
	vim.opt[k] = v
end
