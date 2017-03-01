proc yes(question: string): bool =
  echo question, " (y/n)"
  while true:
    case readLine(stdin)
    of "y", "Y", "yes", "YES", "Yes": return true
    of "n", "N", "no", "NO", "No": return false
    else: echo "Please be clear: yes, or no?"

if yes("Should I delete important things?"):
  echo "But that would be a bad idea."
else:
  echo "Phew."

if "Is this a question?".yes():
  echo "Phew."
else:
  echo "Wat."

discard yes("Is this a pointless question?")
