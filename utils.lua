--- Contains various utilities

--- Duplicates a string n times
function dupString(str, n)
	local s = str;
	for i=1, n do
		s = s .. str;
	end
	return s;
end

--- Resolves a path name
function resolvePath(path)
	if string.sub(path, 1, 1) == "/" then
		return string.sub(path, 2, #path);
	elseif path == "." then
		return shell.dir();
	else
		return shell.dir() .. "/" .. path;
	end
end

--- Whether or not a keycode is a printable char
--- this function may break between versions and there's not
--- really a way for me to prevent that.
function isPrintable(key)
	return (key >= 32 and key <= 126);
end

--- Returns the raw error message (no line number)
function rawError(e)
	local colons = 0;
	local i = 0;
	for i=0, #e do
		local c = string.sub(e, i, i);
		if c == ":" then
			colons = colons+1;
		end
		if colons >= 2 then
			break;
		end
	end
	return string.sub(e, i+1);
end

--- Splits a string
function split(str, sep)
	local t = {};
	for s in string.gmatch(str, "([^" .. sep .. "]+)") do
		table.insert(t, s);
	end
	return t;
end

--- Gets extension of a filename
function getExtension(filename)
	local s = split(filename, ".");
	return s[#s];
end

--- Whether or not a table contains a given key
function contains(table, element)
	for _, e in ipairs(table) do
		if e == element then
			return true;
		end
	end
	return false;
end

--- Returns the whitespace before a string
function precedingWhitespace(str)
	local ws = "";
	for i=1, #str do
		local c = string.sub(str, i, i);
  if c ~= " " and c ~= "\t" then
			break;
		end
		ws = ws .. c;
	end
 return ws;
end