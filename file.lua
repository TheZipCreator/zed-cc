--- Contains the file class

File = {};
--- Creates a new file with the given filename, text, and mode.
--- If mode is unspecified, it sets it to "readwrite"
function File:new(filename, text, mode)
	local res = {}
	setmetatable(res, self);
	self.__index = self;
	local lines = {};
	local s = "";
	for i=1, #text do
		local c = string.sub(text, i, i);
		-- lua doesn't have continue statements, which is very annoying
		-- this can be solved with labels, but apparenly the version of lua that CC runs on does not have gotos or labels
		-- so I'm stuck doing this
		if c == "\r" then
		elseif c == "\n" then
			table.insert(lines, s);
			s = "";
		else 
			s = s .. c;
		end
	end
	if s ~= "" then
		s = table.insert(lines, s);
	end
	res.lines = lines;
	res.name = filename;
	res.mode = mode or "readwrite";
	res.editMode = "none";
	for languageName, language in pairs(languages) do
		if contains(language.extensions, getExtension(res.name)) then
			res.language = languageName
		end
	end
	res.cursorX = 1;
	res.cursorY = 1;
	return res;
end

--- Loads a file from the given filename. Starts searching from the current working directory
function File:load(filename)
	local f = fs.open(resolvePath(filename), "r");
	if f == nil then
		reportError("E0: Cannot find file" .. filename);
		return;
	end
	local ret = File:new(filename, f.readAll());
	f.close();
	return ret;
end

--- Gets all content of the file as one string
function File:content()
	local ret = "";
	for i, line in pairs(self.lines) do
		if i ~= 1 then
			ret = ret .. "\n";
		end
		ret = ret .. line;
	end
	return ret;
end

--- Saves a file
function File:save()
	assert(self.mode == "readwrite", "Cannot save this file.");
	local handle = fs.open(resolvePath(self.name), "w");
	assert(handle ~= nil, "Could not save file");
	local content = self:content();
	handle.write(content);
	handle.close();
	return #content;
end
