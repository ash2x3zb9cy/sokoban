-- splits a string str across characterset sep
function split(str, sep)
	local res = {}
	for part in string.gmatch(str, "([^"..sep.."]+)") do
		table.insert(res, part)
	end
	return res
end
return split
