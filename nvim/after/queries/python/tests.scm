;Capture tests
(function_definition
  name: (identifier) @test_name
  (#match? @test_name "^test_.*")
    ) @func

; Case with a decorated definition
; This will also match the case of multiple decorated definitions
(decorated_definition
  (function_definition
     name: (identifier) @test_name
     (#match? @test_name "^test_.*")
        ) @func

  ) @decorated
