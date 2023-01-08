--- Stores the Zedlisp parser and interpreter

--- Parses Zedlisp into an AST
function parse(code, pos)
	local ret = { type = "list" };
	local s = "";
	local i = pos or 1;
	local function add()
		if s == "" then
			return;
		end
		local num = tonumber(s);
		if num ~= nil then
			table.insert(ret, {
				type = "number",
				value = num
			});
			return;
		end
		table.insert(ret, {
			type = "symbol",
			value = s
		});
	end
	while i <= #code do
		local c = string.sub(code, i, i);
		if c == "(" then
			add();
			local r, p = parse(code, i+1);
			table.insert(ret, r);
			if p == nil then
				error("Unbalanced Parenthesis");
			end
			i = p;
		elseif c == ")" then
			add();
			return ret, i;
		elseif c == " " or c == "\t" or c == "\r" or c == "\n" then
			add();
			s = "";
		elseif c == '"' then
			add();
			repeat
				i = i+1;
				c = string.sub(code, i, i);
				if c == "\\" then
					local n = string.sub(code, i+1, i+1);
					if n == "n" then
						s = s .. "\n";
					elseif n == "r" then
						s = s .. "\r";
					elseif n == "t" then
						s = s .. "\t";
					elseif n == '"' then
						s = s .. '"';
					else
						error("Invalid escape code \\" .. n);
					end
					i = i+1;
				elseif c ~= '"' then	
					s = s .. c;
				end
			until c == '"'
			table.insert(ret, {
				type = "string",
				value = s
			});
			s = "";
		else
			s = s .. c;
		end
		i = i+1;
	end
	add();
	return ret;
end


--- The higher-level "fold" function
function fold(list, fn)
	if #list == 0 then
		return nil;
	end
	local acc = list[1];
	for i=2, #list do
		acc = fn(acc, list[i]);
	end
	return acc;
end

languages = {}; --- Table of all registered languages
themes = {}; --- List of all themes

--- Evaluates a given lisp AST or string and returns a result
function eval(e, context)
	if type(e) == "string" then
		e = parse(e);
	end
	local context = context or {
		message = function(vals)
			local s = "";
			for i, v in pairs(evalAll(vals, context)) do
				if i ~= 0 then
					s = s .. " ";
				end
				s = s .. tostring(v);
			end
			setMessageBar(s, colors.magenta, colors.black);
			-- print(s);
		end,
		q = function(vals)
			assert(textEditorMode, "This command can only be done in text editor mode.");
			exit = true;
		end,
		w = function(vals)
			assert(textEditorMode, "This command can only be done in text editor mode.");
			local f = openFile();
			local count = f:save();
			setMessageBar(f.name .. ": ".. tostring(count) .. " bytes written.", colors.white, colors.black);
		end,
		e = function(vals)
			assert(textEditorMode, "This command can only be done in text editor mode.");
			assert(#vals > 0, "e takes 1 or more parameter");
			local files = evalAll(vals, context);
			for i, file in pairs(files) do
				local f;
				if(fs.exists(resolvePath(file))) then
					f = File:load(file);
				else 
					f = File:new(file, "\n");
				end
				table.insert(openFiles, f);
			end
			setFile(#openFiles);
		end,
		lexer = function(vals)
			local rules = {};
			local keywords = {};
			for _, rule in ipairs(vals) do
				local name = rule[1];
				assert(name.type == "symbol", "Name of rule must be symbol");
				name = name.value;
				local tmp = {};
				for i=2, #rule do
					local pattern = rule[i];
					assert(pattern.type == "string", "Patterns in rule must be strings.");
					table.insert(tmp, pattern.value);
				end
				if name == "keyword" then
					keywords = tmp;
				else
					rules[name] = tmp;
				end
			end
			return function(code)
				local pos = 1;
				local tokens = {};
				local found = false; -- wouldn't be needed if we had gotos or continues with labels but alas, we don't
				while pos <= #code do
					local sub = string.sub(code, pos, #code);
					found = false;
					for rule, patterns in pairs(rules) do
						for _, pattern in ipairs(patterns) do
							local a, b = string.find(sub, pattern);
							if a ~= nil and a == 1 then
								-- match found
								local t = rule;
								local v = string.sub(sub, a, b);
								if rule == "identifier" then
									if contains(keywords, v) then
										t = "keyword"
									end
								end
								table.insert(tokens, {
									type = t,
									value = v;
								});
								pos = pos+b;
								found = true;
								break;
							end
						end
						if found then
							break;
						end
					end
					if not found then
						table.insert(tokens, {
							type = "unknown",
							value = string.sub(sub, 1, 1);
						});
						pos = pos+1;
					end
				end
				return tokens;
			end
		end,
		language = function(vals)
			local all = evalAll(vals, context);
			assert(#all == 3, "language takes three arguments.");
			local name = all[1];
			assert(type(name) == "string", "Name of language must be string.");
			local extensions = all[2];
			assert(type(extensions) == "table", "Extensions must be a table.");
			local lexer = all[3];
			assert(type(lexer) == "function", "Lexer must be function.");
			languages[name] = {
				lexer = lexer,
				extensions = extensions
			}
		end,
		theme = function(vals)
			assert(#vals == 2, "theme takes two arguments.");
			local name = vals[1];
			assert(name.type == "string", "Name of the theme must be a string.");
			name = name.value;
			local tokens = vals[2];
			assert(tokens.type == "list", "Tokens must be a list.");
			local tmp = {};
			for _, token in ipairs(tokens) do
				assert(#token == 2, "Each token must have 2 elements");
				local tokenName = token[1];
				assert(tokenName.type == "symbol", "Token name must be a symbol.");
				tokenName = tokenName.value;
				local color = token[2];
				assert(color.type == "string", "Color must be a string.");
				color = color.value;
				local c2 = colors[color];
				if c2 == nil then
					c2 = colours[color];
				end
				assert(c2 ~= nil, "Invalid color.");
				tmp[tokenName] = c2;
			end
			themes[name] = tmp;
		end,
		["+"] = function(vals)
			return fold(evalAll(vals, context), function(a, b) return a+b end);
		end,
		["-"] = function(vals)
			return fold(evalAll(vals, context), function(a, b) return a-b end);
		end,
		["*"] = function(vals)
			return fold(evalAll(vals, context), function(a, b) return a*b end);
		end,
		["/"] = function(vals)
			return fold(evalAll(vals, context), function(a, b) return a/b end);
		end,
		["%"] = function(vals)
			return fold(evalAll(vals, context), function(a, b) return a%b end);
		end,
		list = function(vals)
			return evalAll(vals, context);
		end
	};
	function evalAll(vals, context)
		local list = {};
		for _, v in pairs(vals) do
			table.insert(list, eval(v, context));
		end
		return list;
	end
	if e.type == "symbol" then
		local ret = context[e.value];
		if ret == nil then
			error("Undefined symbol '" .. e.value .. "'.");
		end
		return ret;
	elseif e.type == "number" then
		return e.value;
	elseif e.type == "string" then
		return e.value;
	elseif e.type == "list" then
		if #e == 0 then
			error("Empty list");
		end
		local fn = eval(e[1], context);
		if type(fn) ~= "function" then
			error("Attempted to call non-function " .. tostring(fn));
		end
		local vals = {};
		for i=2, #e do
			table.insert(vals, e[i]);
		end
		return fn(vals);
	end
	error("Unknown type: " .. e.type);
end

--- Evals from a file
function evalFile(filename)
	local h = fs.open(filename, "r");
	local ret = eval(h.readAll());
	h.close();
	return ret;
end

--- Runs everything under the scripts/ directory
function runScripts(dir)
	dir = dir or "zed/scripts";
	for _, file in ipairs(fs.list(dir)) do
		file = dir .. "/" .. file;
		if fs.isDir(file) then
			runScripts(file)
		else
			if getExtension(file) == "lisp" then
				evalFile(file);
			end
		end
	end
end
