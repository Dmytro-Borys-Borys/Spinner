#!/bin/bash

message="$1"
command="$2"

printf "\n"
spinner_chars=("⠇" "⠋" "⠙" "⠸" "⠴" "⠦")
spinner_idx=0

# ANSI escape sequences for color formatting and cursor control
adjust="\033["
green_color="${adjust}32m"
red_color="${adjust}31m"
default_color="${adjust}0m"
bold_text="${adjust}1m"
hide_cursor="${adjust}?25l"
show_cursor="${adjust}?25h"
erase_till_end_of_line="${adjust}K"
clear_screen_from_cursor="${adjust}J"

output_file="output.txt"  # File to store the command output
touch "$output_file"
maxlines=6

# Run the command in the background while piping the output to tee
eval "$command" 2>&1 > "$output_file" &

# Capture the process ID of the background command
cmd_pid=$!

# Hide the cursor
echo -ne "$hide_cursor"

# Display the spinner until the background command exits
while true; do


  spinner="${spinner_chars[spinner_idx]}"
  mapfile -t lines < "$output_file"  # Read the lines from the output file into an array
  readlines=${#lines[@]}  # Get the number of lines in the array

  # Print the spinner and message
  printf "${adjust}1A\r%s %s${adjust}1B\r" "$spinner" "$message"

  # Print the last 6 lines from the array
  start_index=$((readlines - maxlines))
  start_index=$((start_index > 0 ? start_index : 0))
  for ((i = start_index; i < readlines; i++)); do
    echo "${lines[i]}"
  done

  # Adjust the cursor position
  displacement=$((readlines - start_index))
  if [ $readlines -gt 0 ]; then
    printf "${adjust}%dA" "$displacement"
  fi

  spinner_idx=$(( (spinner_idx + 1) % ${#spinner_chars[@]} ))
  sleep 0.1
  if ! kill -0 "$cmd_pid" >/dev/null 2>&1; then
    break  # Break the loop if the command has finished
  fi
done

# Wait for the background command to finish and capture the exit code
wait "$cmd_pid"
exit_code=$?



# Print the status message
if [ $exit_code -eq 0 ]; then
  echo -e "${adjust}1A\r${green_color}✔️ ${default_color}${message}:${bold_text}${green_color} SUCCESS ${default_color}${clear_screen_from_cursor}"
else
  echo -e "${adjust}1A\r${red_color}✖️ ${default_color}${message}:${bold_text}${red_color} FAILED${default_color} (error $exit_code)${clear_screen_from_cursor}"
  echo -ne "${red_color}"
  cat $output_file
  echo -ne "${default_color}"
fi

# Remove the output file
rm "$output_file"

# Show the cursor again
echo -ne "$show_cursor"

# Return the exit code of the command
exit $exit_code