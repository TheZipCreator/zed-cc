--- Contains the main event loop & file class

require("utils");
require("display");
require("lisp");
require("file");
pretty = require("cc.pretty");

term.clear();

fileIndex = 1;  --- Index of the currently open file
openFiles = {}; --- Currently open files

--- Gets the currently open file
function openFile()
	return openFiles[fileIndex];
end

scrollX = 0; --- Scroll in X direction
scrollY = 0; --- Scroll in Y direction
cursorX = 1; --- X component of cursor
cursorY = 1; --- Y component of cursor

--- Moves the cursor to the given location
function moveCursor(x, y, wrap)
	local lines = openFile().lines;
	cursorX = x;
	cursorY = y;
	local line = lines[cursorY];
	function checkY()
		if cursorY > #lines then
			cursorY = #lines;
		elseif cursorY < 1 then
			cursorY = 1;
		end
		line = lines[cursorY];
	end
	function checkX()
		if cursorX > #line+1 then
			if cursorY < #lines then
				if wrap then
					cursorY = cursorY+1;
					checkY();
					cursorX = 1;
				else
					cursorX = #line+1;
				end
			else
				cursorX = #line+1;
			end
		elseif cursorX < 1 then
			if cursorY > 1 then
				cursorY = cursorY-1;
				checkY();
				cursorX = #line;
			else
				cursorX = 1;
			end
		end	
	end
	checkY();
	checkX();
	while cursorX > width+scrollX do
		scrollX = scrollX+1;
	end
	while cursorX < scrollX+1 do
		scrollX = scrollX-1;
	end
	while cursorY > height-2+scrollY do
		scrollY = scrollY+1;
	end
	while cursorY < scrollY+1 do
		scrollY = scrollY-1;
	end
end

--- Moves the cursor by the given offset
function offsetCursor(x, y, wrap)
	moveCursor(cursorX+x, cursorY+y, wrap);
end



version = "1.0.0"; --- Current version of Zed

theme = "default"; --- Current theme

runScripts();

local args = {...};
for _, file in pairs(args) do
	local f = File:load(file);
	if f == nil then
		f = File:new(file, "\n");
	end
	table.insert(openFiles, f);
end

function createIntroFile()
	table.insert(openFiles, File:new(".zedinfo", "Welcome to zed V" .. version .. "!\nType <i> to begin editing, or type <h> for help.", "zedinfo"));
end

if #openFiles == 0 then
	createIntroFile();
end

mode = "none";

--- Sets file to a given index
function setFile(idx, preserve)
	if preserve == nil then
		preserve = true;
	end
	if idx < 1 or idx > #openFiles then
		reportError("E1: File index out of bounds.");
		return;
	end
	if preserve then
	local of = openFile();
		of.editMode = mode;
		of.cursorX = cursorX;
		of.cursorY = cursorY;
	end
	fileIndex = idx;
	local f = openFile();
	moveCursor(f.cursorX, f.cursorY);
	setMode(f.editMode);
end

--- Sets the mode to the given mode
function setMode(newMode)
	mode = newMode;
	if mode == "none" then
		clearMessageBar();
		term.setCursorBlink(true);
	elseif mode == "insert" then
		setMessageBar("-- INSERT --", colors.white, colors.black);
		local f = openFile();	
		if f.mode == "readonly" then
			reportError("This file is read-only!");
			mode = "none";
			return;
		end
		if f.mode == "zedinfo" then
			f.lines = {""};
			f.mode = "readwrite";
			f.name = "untitled";
			moveCursor(1, 1);
		end
		term.setCursorBlink(true);
	elseif mode == "command" then
		command = "";
		commandCursor = 1;
		setMessageBar(":", colors.white, colors.black);
		term.setCursorBlink(true);
	end
end

command = "";
commandCursor = 1;

setFile(1);

local actions = {
	none = {
		[keys.i] = function()
			setMode("insert");
		end,
		[keys.h] = function()
			table.insert(openFiles, File:load("/zed/help.zedinfo", "readonly"));
			setFile(#openFiles);	
		end,
		[keys.semicolon] = function()
			setMode("command");
		end,
		[keys.period] = function()
			if fileIndex+1 > #openFiles then
				return;
			end
			setFile(fileIndex+1);
		end,
		[keys.comma] = function()
			if fileIndex-1 < 1 then
				return;
			end
			setFile(fileIndex-1);
		end
	},
	insert = {	
		[keys.delete] = function()
			local f = openFile();
			local l = f.lines[cursorY];
			if #l > 0 then
				f.lines[cursorY] = string.sub(l, 1, cursorX-1) .. string.sub(l, cursorX+1, #l);	
			end
		end,
		[keys.backspace] = function()
			local f = openFile();
			local l = f.lines[cursorY];
			if cursorX > 1 then
				f.lines[cursorY] = string.sub(l, 1, cursorX-2) .. string.sub(l, cursorX, #l);
				offsetCursor(-1, 0);
			elseif cursorY > 1 then
				table.remove(f.lines, cursorY);
				cursorY = cursorY-1;
				f.lines[cursorY] = f.lines[cursorY] .. l;
				moveCursor(#f.lines[cursorY]+1, cursorY);
			end
		end,
		[keys.enter] = function()
			local f = openFile();
			local l = f.lines[cursorY];
			local ws = precedingWhitespace(l);
			local sub = string.sub(l, cursorX, #l);
			f.lines[cursorY] = string.sub(l, 0, cursorX-1);
			table.insert(f.lines, cursorY+1, ws .. sub);
			moveCursor(#ws+1, cursorY+1);
		end,
		[keys.tab] = function()
			local f = openFile();
			local l = f.lines[cursorY];
			f.lines[cursorY] = string.sub(l, 1, cursorX-1) .. "\t" .. string.sub(l, cursorX, #l);
			offsetCursor(1, 0);
		end,
		[keys.pageUp] = function()
			offsetCursor(0, -height);
		end,
		[keys.pageDown] = function()
			offsetCursor(0, height);
		end
	},
	command = {
		[keys.leftCtrl] = function()
			setMode("none");
		end,
		[keys.left] = function()
			commandCursor = commandCursor-1;
			if commandCursor <= 1 then
				commandCursor = 1;
			end
		end,
		[keys.right] = function()
			commandCursor = commandCursor+1;
			if commandCursor > #command+1 then
				commandCursor = #command+1;
			end
		end,
		[keys.backspace] = function()
			if #command > 0 then
				command = string.sub(command, 1, commandCursor-2) .. string.sub(command, commandCursor, #command);
				commandCursor = commandCursor-1;
			else
				setMode("none");
			end
		end,
		[keys.enter] = function()
			setMode("none");
			local ret;
			local status, err = pcall(function()
				ret = eval(command)
			end);
			if err ~= nil then
				reportError(rawError(err));
			elseif ret ~= nil then
				setMessageBar(pretty.pretty(ret), colors.magenta, colors.black);
			end
		end
	}
};

local function addArrowKeys(obj)
	obj[keys.leftCtrl] = function()
		setMode("none");
	end;
	obj[keys.left] = function()
		offsetCursor(-1, 0, true);
	end;
	obj[keys.right] = function()
		offsetCursor(1, 0, true);
	end;
	obj[keys.up] = function()
		offsetCursor(0, -1, false);
	end;
	obj[keys.down] = function()
		offsetCursor(0, 1, false);
	end;
end

addArrowKeys(actions.insert);
addArrowKeys(actions.none);

displayOpenFiles();

textEditorMode = true; --- tell lisp we're in text editor mode

shiftHeld = false;
exit = false;
local status, err = pcall(function() 
	while not exit do
		displayFile();
		displayOpenFiles();
		displayLineCol();
		displayCursor();
		local evt, key = os.pullEvent("key");
		local action = actions[mode][key];
		if action ~= nil then
			action();	
		elseif mode == "insert" then
			if isPrintable(key) then
				local f = openFile();
				local l = f.lines[cursorY];
				local _, char = os.pullEvent("char");
				f.lines[cursorY] = string.sub(l, 1, cursorX-1) .. char .. string.sub(l, cursorX, #l);
				offsetCursor(1, 0);
			end
		elseif mode == "command" then
			if isPrintable(key) then
				local _, char = os.pullEvent("char");
				command = string.sub(command, 1, commandCursor-1) .. char .. string.sub(command, commandCursor, #command);
				commandCursor = commandCursor+1;
			end
		end
		if mode == "command" then
			setMessageBar(":" .. command, colors.white, colors.black);
		end
	end
end);
term.clear();

if err ~= nil then
	term.setBackgroundColor(colors.black);
	term.setTextColor(colors.red);
	print("Zed has encountered an unrecoverable error:");
	print(err);
end