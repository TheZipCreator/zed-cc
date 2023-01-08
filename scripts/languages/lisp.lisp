language "lisp" (list "lisp") (lexer
	(whitespace "[ \t\n\r]+")
	(identifier "[a-zA-Z_%-][a-zA-Z_%-0-9]*")
	(number "[0-9]+" "[0-9]+%.[0-9]*")
	(punctuation "[%(%)]")
	(string "\"[^\"]*\""))