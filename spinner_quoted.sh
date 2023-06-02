#!/bin/bash

message="$1"
command="$2"

printf "\n\n"
spinner_chars=("⠇" "⠋" "⠙" "⠸" "⠴" "⠦")
spinner_idx=0

# ANSI escape sequences for color formatting and cursor control
green_color="\033[32m"
red_color="\033[31m"
default_color="\033[0m"
bold_text="\033[1m"
hide_cursor="\033[?25l"
show_cursor="\033[?25h"

counter_file="counter.txt"  # File to store the line counter
touch $counter_file
maxlines=6
readlines=0  # Counter for lines read and printed
# Run the command in the background while piping the output to tee
eval "$command" 2>&1 | {
  
  
  lines=()  # Array to store captured lines

  while IFS= read -r line; do
    lines+=("$line")  # Add line to the array
    readlines=$((readlines + 1))  # Increment the line counter
    echo "$readlines" > "$counter_file"
    if ((readlines > maxlines)); then
      for ((j = readlines - maxlines; j < readlines; j++)); do
        printf "\033[%dA\r${lines[j]}\033[K\033[%dB" $((readlines-j)) $((readlines-j))

      done
    else
      printf "\r$line\n"
    fi

    # Write the readlines count to the counter file
    
  done
} &

# Capture the process ID of the background command
cmd_pid=$!

# Hide the cursor
echo -ne "$hide_cursor"

# Display the spinner until the background command exits
while kill -0 "$cmd_pid" >/dev/null 2>&1; do
  spinner="${spinner_chars[spinner_idx]}"
  readlines=$(<"$counter_file")  # Read the readlines count from the counter file
  displacement=$((readlines < maxlines ? readlines+1 : maxlines+1))
  printf "\033[%dA\r_%d_%s_%s\033[%dB\r" "$displacement" "$displacement" "$spinner" "$message" "$displacement"
  spinner_idx=$(( (spinner_idx + 1) % ${#spinner_chars[@]} ))
  sleep 0.1
done

# Wait for the background command to finish and capture the exit code
wait "$cmd_pid"
exit_code=$?

# Show the cursor again
echo -ne "$show_cursor"
readlines=$(<"$counter_file")  # Read the readlines count from the counter file
displacement=$((readlines < maxlines ? readlines+1 : maxlines+1))
# Print the status message
if [ $exit_code -eq 0 ]; then
  echo -e "\033[${displacement}A\r${green_color}✔️ ${default_color}${message}:${bold_text}${green_color} SUCCESS ${default_color}\033[K\033[${displacement}B"
  #tput ed
else
  echo -e "\033[${displacement}A\r${red_color}✖️ ${default_color}${message}:${bold_text}${red_color} FAILED${default_color} (error $exit_code)"
fi

# Remove the counter file
#rm "$counter_file"

# Return the exit code of the command
exit $exit_code
