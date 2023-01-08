language "lua" (list "lua") (lexer
	(whitespace "[ \r\n\t]")
	(comment "--[^\n]\n") 
	(identifier "[a-zA-Z_][a-zA-Z0-9_]*")
	(keyword "and" "break" "do" "else" "elseif" "end" "false" "for" "function" "if" "in" "local" "nil" "not" "or" "repeat" "return" "then" "true" "until" "while")
	(string "\"[^\"]*\"" "'[^']*'")
	(punctuation "%+" "%-" "%*" "%/" "%%" "%^" "#" "==" "~=" "<=" ">=" "<" ">" "=" "%(" "%)" "{" "}" "%[" "%]" ";" ":" "," "%." "%.%." "%.%.%.")
	(number "[0-9]+" "[0-9]+%.[0-9]+"))    
