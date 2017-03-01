
proc `@$%` *[T](arg: T): string =
  discard arg
  result = "Unfortunately, you can export overloaded operators for base types."

echo "Concat test 1: ", "a" & "b"
proc `&`*(a, b: string): string =
  discard a
  discard b
  result = "Unfortunately, you can override built-in operators."
echo "Concat test 2: ", "a" & "b"
