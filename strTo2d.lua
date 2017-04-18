function strTo2d(str, cb)
	local tbl = {}
	local split = require 'split'
	local rows = split(str, '\n')
	for y, row in pairs(rows) do
		rowTbl = {}
		for x=1, #row do
			local item = row:sub(x, x)
			if cb ~= nil then item = cb(item, x, y, rowTbl, tbl) end
			table.insert(rowTbl, item)
		end
		table.insert(tbl, rowTbl)
	end
	return tbl
end
return strTo2d
