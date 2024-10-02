local wezterm = require("wezterm")

local module = {}

function module.is_darwin()
	return wezterm.target_triple:find("darwin") ~= nil
end

return module
