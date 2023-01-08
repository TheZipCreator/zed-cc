--- Contains code for displaying things to the screen

width, height = term.getSize();

--- Sets terminal colors to fg, bg
local function setColor(fg, bg)
	term.setTextColor(fg);
	term.setBackgroundColor(bg);
end

--- Clears the message bar
function clearMessageBar()
	setMessageBar("", colors.white, colors.black);
end

--- Displays an error on the message bar
function reportError(err)
	setMessageBar(err, colors.white, colors.red);
end

--- Displays a message to the message bar, with a given foreground and background colors
function setMessageBar(text, fg, bg)
	setColor(fg, bg);
	term.setCursorPos(1, height);
	term.write(dupString(" ", width));
	term.setCursorPos(1, height);
	term.write(text);
end

--- Displays all open files
function displayOpenFiles()
	term.setCursorPos(1, 1);
	setColor(colors.white, colors.black);
	term.write(dupString(" ", width));
	term.setCursorPos(1, 1);
	local n = fileIndex-1;
	if n < 1 then
		n = 1;
	end
	for i=n, #openFiles do
		local file = openFiles[i];
		if i == fileIndex then
			setColor(colors.black, colors.green);
		else
			setColor(colors.black, colors.white);
		end
		term.write(file.name);
		setColor(colors.white, colors.black);
		term.write(" ");
	end
end

--- Displays the currently open file
function displayFile()
	local f = openFile();
	for i=1,height-2 do
		local pos = i+scrollY;
		term.setCursorPos(1, i+1);
		setColor(colors.white, colors.black);
		term.write(dupString(" ", width));
		term.setCursorPos(1, i+1);
		if pos <= #f.lines then
			setColor(colors.white, colors.black);
			local line = f.lines[pos];
			if #line-scrollX ~= 0 then
				term.setCursorPos(1-scrollX, i+1);
				if f.language == nil  then
					term.write(line);
				else
					local tokens = languages[f.language].lexer(line);
					for _, token in ipairs(tokens) do
						local color = themes[theme][token.type] or colors.white;
						setColor(color, colors.black);
						term.write(token.value);
					end
				end
			end
		elseif scrollX == 0 then
			setColor(colors.blue, colors.black);
			term.write("~");
		end
	end
end

--- Moves the cursor to the right spot for blinking cursor
function displayCursor()
	if mode == "command" then
		term.setCursorPos(commandCursor+1, height);
	else
		term.setCursorPos(cursorX-scrollX, cursorY-scrollY+1);
	end
end
