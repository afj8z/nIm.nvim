local cjson = require("cjson")

local arg = cjson.encode({ 1, 2, 3, { x = 10 } })

local function to_json(jsonpath, msg)
	json_f = io.open(jsonpath, "a+")
	io.output(json_f)
	io.write(msg)
	io.close(msg)
end

local function find_assign(fpath, jsonpath)
	json_f = io.open(jsonpath, "a+")
	print(json_f:read("*a"))
end

local function update_state(fpath, jsonpath, msg) end

-- to_json("test.json", arg)
