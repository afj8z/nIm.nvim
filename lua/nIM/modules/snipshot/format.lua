local check = require("util.error_checks")
local input = "typ"

local ft = {
	"typ",
	"txt",
	"md",
}
local filetype

function test()
	check.verify_key(ft, input, "Test error input ft not registered")
end

test()
