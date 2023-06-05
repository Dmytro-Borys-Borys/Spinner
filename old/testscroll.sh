{
  maxlines=6
  readlines=0  # Counter for lines read and printed
  lines=()  # Array to store captured lines

  while IFS= read -r line; do
    lines+=("$line")  # Add line to the array
    Ireadlines=$((readlines + 1))  # Increment the line counter

    if ((readlines >maxlines)); then
      tput cuu $maxlines  # Move the cursor up 8 lines
      tput el  # Clear the lines
      for ((j = readlines - maxlines; j < I; j++)); do
        printf "${lines[j]}\n"
      done
    else
      printf "$line\n"
    fi
  done
} < <(for ((i = 1; i <= 20; i++)); do echo "Output line $i"; sleep 1; done)
