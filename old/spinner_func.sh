#!/bin/bash

run_with_spinner() {
  local message="$1"
  shift
  local command=("$@")

  local spinner_chars=("⠇" "⠋" "⠙" "⠸" "⠴" "⠦")
  local spinner_idx=0

  # ANSI escape sequences for color formatting and cursor control
  local green_color="\033[32m"
  local red_color="\033[31m"
  local default_color="\033[0m"
  local bold_text="\033[1m"
  local hide_cursor="\033[?25l"
  local show_cursor="\033[?25h"
  # Run the command in the background
  "${command[@]}" &

  # Capture the process ID of the background command
  local cmd_pid=$!

  # Hide the cursor
  echo -ne "$hide_cursor"

  # Display the spinner until the background command exits
  while kill -0 "$cmd_pid" >/dev/null 2>&1; do
    local spinner="${spinner_chars[spinner_idx]}"
    printf "\r%s %s" "$spinner" "$message"
    spinner_idx=$(( (spinner_idx + 1) % ${#spinner_chars[@]} ))
    sleep 0.1
  done

  # Wait for the background command to finish and capture the exit code
  wait "$cmd_pid"
  local exit_code=$?

  # Show the cursor again
  echo -ne "$show_cursor"

  # Check the exit code and print the appropriate message in the corresponding color
  if [ $exit_code -eq 0 ]; then
    echo -e "\r${green_color}✔️ ${default_color}${message}:${bold_text}${green_color} SUCCESS${default_color}"
  else
    echo -e "\r${red_color}✖️ ${default_color}${message}:${bold_text}${red_color} FAILED${default_color} (error $exit_code)"
  fi

  # Return the exit code of the command
  return $exit_code
}

