#!/bin/bash

quiet_mode=false

if [ "$1" = "-q" ] || [ "$1" = "--quiet" ]; then
  quiet_mode=true
  shift
fi

if [ $# -lt 1 ]; then
  echo "Usage: $0 [-q|--quiet] <command> [message]"
  exit 1
fi

command="$1"
message="$2"

if [ -z "$message" ]; then
  message="$command"
fi

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
lines_up="A"
lines_down="B"

output_file="output.txt" # File to store the command output
if [ -f "$output_file" ]; then
  rm -f "$output_file" # Remove existing output file if present
fi

# Max number of lines to print at the bottom
maxlines=6

# Get the number of columns in the current terminal
columns=$(tput cols)

# Run the command in the background while piping the output to tee
eval "$command" >"$output_file" 2>&1 &

# Capture the process ID of the background command
cmd_pid=$!

# Hide the cursor
echo -ne "$hide_cursor"

previous_timestamp=0  # Initialize previous timestamp to 0

# Display the spinner until the background command exits
while true; do
  
  spinner="${spinner_chars[spinner_idx]}"
  # Print the spinner and message
  printf "${adjust}1${lines_up}\r%s %s${adjust}1${lines_down}\r" "$spinner" "$message"
  spinner_idx=$(((spinner_idx + 1) % ${#spinner_chars[@]}))

  if [ "$quiet_mode" = false ]; then
    current_timestamp=$(stat -c %Y "$output_file")  # Get the current modification timestamp

      # Check if the file has been modified since the last iteration
      if [ "$current_timestamp" -gt "$previous_timestamp" ]; then
          mapfile -t lines < "$output_file"  # Read the lines from the output file into an array
          readlines=${#lines[@]}            # Get the number of lines in the array
          printf "${clear_screen_from_cursor}"
          # Print the last lines from the array
          start_index=$((readlines - maxlines))
          start_index=$((start_index > 0 ? start_index : 0))
          for ((i = start_index; i < readlines; i++)); do
              # Truncate the line to the number of columns
              printf "%s\n\r" "${lines[i]:0:columns}"
          done

          # Adjust the cursor position
          displacement=$((readlines - start_index))
          if [ "$readlines" -gt 0 ]; then
              printf "${adjust}%d${lines_up}" "$displacement"
          fi

          previous_timestamp=$current_timestamp  # Update the previous timestamp
      fi
  fi

  sleep 0.1
  if ! kill -0 "$cmd_pid" >/dev/null 2>&1; then
    break # Break the loop if the command has finished
  fi
done

# Wait for the background command to finish and capture the exit code
wait "$cmd_pid"
exit_code=$?

# Print the status message
if [ $exit_code -eq 0 ]; then
  echo -ne "${adjust}1${lines_up}\r"                              # move cursor 1 line up
  echo -ne "${green_color}✔️${default_color}"                     # show check mark
  echo -ne " ${message}"                                          # print message string
  echo -ne ":${bold_text}${green_color} SUCCESS ${default_color}" # print SUCCESS in green
  echo -e "${clear_screen_from_cursor}"                           # clean up
else
  echo -ne "${adjust}1${lines_up}\r"                                             # move cursor 1 line up
  echo -ne "${red_color}✖️${default_color}"                                      # show check mark
  echo -ne " ${message}"                                                         # print message string
  echo -ne ":${bold_text}${red_color} FAILED ${default_color}(error $exit_code)" # print FAILED in red and show error code
  echo -e "${clear_screen_from_cursor}"                                          # clean up
  echo -ne "${red_color}"                                                        # switch to red
  cat "$output_file"                                                             # print entire error output
  echo -ne "${default_color}"                                                    # reset color
fi

# Remove the output file
rm "$output_file"

# Show the cursor again
echo -ne "$show_cursor"

# Return the exit code of the command
exit $exit_code
