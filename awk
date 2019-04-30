# sub col
awk '{print $2,$4,$5}' input.txt > output.txt

# change --field-separator to :
awk -F: '{print $1}'

# match
awk '/^test[0-9]+/' input.txt

# count number of times
awk '{l[$1]++}END{for (x in l) print x,l[x]}' input.txt
