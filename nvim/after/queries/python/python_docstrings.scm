; python_docstrings.scm

; Module docstring
(module . (expression_statement (string) @comment))

; Module docstring
(module
  (expression_statement (string) @comment)
  (#match? @comment "^\"\"\"")
  (#match? @comment "\"\"\"$"))

; Class docstring
(class_definition
  body: (block . (expression_statement (string) @comment)))

; Function/method docstring
(function_definition
  body: (block . (expression_statement (string) @comment)))

; Attribute docstring
((expression_statement (assignment)) . (expression_statement (string) @comment))
 

; License headers that are blocks of comments at the beginning of a file
(module
  (expression_statement (string) @comment)
  (#match? @comment "^#")
  (#match? @comment "^#.*$")
  (#match? @comment "^#.*$"))
