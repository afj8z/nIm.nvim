local M = {}

function M.verify_key(set, key, msg)
	if set[key] ~= nil then
		return set[key]
	else
		error(msg)
	end
end

return M
