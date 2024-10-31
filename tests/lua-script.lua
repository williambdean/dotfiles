vim.ui.input({
  prompt = "Enter value for shiftwidth: ",
  default = "Something",
}, function(input)
  print("This the the input")
end)
