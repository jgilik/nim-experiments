echo "hello world"
echo "what's your name?"
var name: string = readLine(stdin)
echo "hi, ", name, "!"

case name
of "": echo "Funny, no name."
of "name": echo "Funny, your name is name!"
else: discard
