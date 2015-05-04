local M = {}

function M.in_table(table,item)
	for _,v in pairs(table) do
		if v == item then return true end
	end
	return false
end

return M
