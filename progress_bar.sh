#!/bin/bash

#    An asynchronous progress bar inspired by APT PackageManagerFancy Progress
#    Copyright (C) 2018  Kristoffer Minya
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <https://www.gnu.org/licenses/>
set -a

# The following terms are used for maintainment
# FIXME  :   Code that needs to improved or does not work
# DEBUG  :   Code that needs to be debugged
# TEST   :   Code that needs to be tested for alternatives 
# TODO   :   Reminder for code that needs to be added or changed
# FUTURE :   For future changes, this must be considered
# IDEA   :   Ideas for future improvement or added features

percentage="0.0"
last_reported_progress=-1

#-- In which rate reporting should be done
reporting_steps=${reporting_steps:-1}       # reporting_step can be set by the caller, defaults to 1

foreground="${foreground:-$(tput setaf 0)}" # Foreground can be set by the caller, defaults to black
background="${background:-$(tput setab 2)}" # Background can be set by the caller, defaults to green
reset_color="$(tput sgr0)"

#-- Options to change progressbar look
LEFT_BRACKET="${LEFT_BRACKET:-[}"
RIGHT_BRACKET="${RIGHT_BRACKET:-]}"
FILL="${FILL:-#}"
REMAIN="${REMAIN:-.}"

#-- Command aliases for readability
save_cursor='tput sc'
restore_cursor='tput rc'
disable_cursor='tput civis'
enable_cursor='tput cnorm'
scroll_area='tput csr'
move_to='tput cup'
move_up='tput cuu'
flush='tput ed'


# Bash does not handle floats
# This section defines some math functions using awk
# ==================================================
export LC_ALL=C

math::floor() {
  #-- This function takes a pseudo-floating point as argument
  #-- and rounds down to nearest integer
  awk -v f="$1" 'BEGIN{f=int(f); print f}'
}

math::round() {
  #-- This function takes a pseudo-floating point as argument
  #-- and rounds to nearest integer
  awk -v f="$1" 'BEGIN {printf "%.0f\n", f}'
}

math::min() {
  #-- Takes two values as arguments and compare them
  awk -v f1="$1" -v f2="$2" 'BEGIN{if (f1<=f2) min=f1; else min=f2; print min "\n"}'
}

math::max() {
  #-- Takes two values as arguments and compare them
  awk -v f1="$1" -v f2="$2" 'BEGIN{if (f1>f2) max=f1; else max=f2; print max "\n"}'
}

math::calc() {
  #-- Normal calculator
  awk "BEGIN{print $*}"
}


####################################################




# The main function stack
# ==================================================

draw_progress_bar(){
  bar::status_changed "$1" 100
}

__tty_size(){
  HEIGHT="$(stty size | cut -f1 -d' ')"
  WIDTH="$(stty size | cut -f2 -d' ')"
}

__change_scroll_area() {
  local -i n_rows=$1
  #-- Return if number of lines is 1
  if (( n_rows <= 1)); then
    return 1
  fi

  ((n_rows-=2))

  #-- Go down one line to avoid visual glitch 
  #-- when terminal scroll region shrinks by 1
  echo

  #-- Save cursor position
  eval "${save_cursor}"

  #-- Set scroll region
  eval "${scroll_area} 0 $n_rows"

  #-- Restore cursor
  eval "${restore_cursor}"

  #-- Move up 1 line in case cursor was saved outside scroll region
  eval "${move_up} 2"

  echo

  #-- Set tty size to reflect changes to scroll region
  #-- this is to avoid i.e pagers to override the progress bar
  ((++n_rows))

  #-- Temporarily disabling SIGWINCH to avoid a loop caused by stty sending SIGWINCH whenever theres a change in size
  trap '' WINCH
  stty rows "$n_rows"
  trap handle_sigwinch WINCH
}

__status_changed() {
  local -i StepsDone TotalSteps __int_percentage
  
  ((StepsDone=$1))
  ((TotalSteps=$2))
  
  #-- FIXME
  #-- Sanity check reporting_steps, if this value is too big no progress will be written
  #-- Should that really be checked here?

  percentage=$(math::calc "$(math::calc "$StepsDone/$TotalSteps")*100.00")

  ((__int_percentage=$(math::round "$percentage")))

  printf -v progress_str "Progress: [%3li%%]" "$__int_percentage"

  if (( __int_percentage < (last_reported_progress + reporting_steps) )); then
    return 1
  else
    return 0
  fi
}

__progress_string() {
  local output Percent
  local -i OutputSize BarSize BarDone it
  
  output=""
  Percent="$1"
  ((OutputSize=$2))

  #-- Return an empty string if OutputSize is less than 3
  if ((OutputSize < 3)); then
    echo "$output"
    return 1
  fi

  ((BarSize=OutputSize-2))
  
  BarDone=$(math::max 0 "$(math::min "$BarSize" "$(math::floor "$(math::calc "$Percent*$BarSize")")")")
  
  output="${LEFT_BRACKET}"
  for (( it = 0; it < BarDone; it++ )); do
    output+="${FILL}"
  done
  for (( it = 0; it < BarSize - BarDone; it++ )); do
    output+="${REMAIN}"
  done
  output+="${RIGHT_BRACKET}"
  
  echo "$output"

  return 0
}

__draw_status_line(){
  __tty_size
  if (( HEIGHT < 1 || WIDTH < 1 )); then
    return 1
  fi

  local current_percent progress_bar
  local -i padding progressbar_size
  ((padding=4))

  progress_bar=""

  #-- Save the cursor
  eval "${save_cursor}"
  #-- Make cursor invisible
  eval "${disable_cursor}"

  #-- Move to last row
  eval "${move_to} $((HEIGHT)) 0"
  printf '%s' "${background}${foreground}${progress_str}${reset_color}"

  ((progressbar_size=WIDTH-padding-${#progress_str}))
  current_percent=$(math::calc "$percentage/100.00")
  
  progress_bar="$(__progress_string "${current_percent}" "${progressbar_size}")"

  printf '%s' " ${progress_bar} "

  #-- Restore the cursor
  eval "${restore_cursor}"
  eval "${enable_cursor}"

  ((last_reported_progress=$(math::round "$percentage")))

  return 0
}


bar::start() {
  #-- TODO: Track process that called this function
  # proc...
  E_START_INVOKED=-1
  __tty_size
  __change_scroll_area "$HEIGHT"
}

bar::stop() {
  E_STOP_INVOKED=-1
  if (( ! ${E_START_INVOKED:-0} )); then
    echo "Warn: bar::stop called but bar::start was not invoked" >&2 
    echo "Returning.." # Exit or return?
    return 1
  fi
  #-- Reset bar::start check
  E_START_INVOKED=0

  __tty_size
  if ((HEIGHT > 0)); then
    #-- Passing +2 here because we changed tty size to 1 less than it actually is
    __change_scroll_area $((HEIGHT+2))

    #-- tput ed might fail (OS X) in which case we force clear
    trap 'printf "\033[J"' ERR

    #-- Flush progress bar
    eval "${flush}"
   
    trap - ERR
    #-- Go up one row after flush
    eval "${move_up} 1"
    echo
  fi
  #-- Restore original (if any) handler
  trap - WINCH
  return 0
}

#-- FIXME: Pass worker pid?
bar::status_changed() {
  if (( ! ${E_START_INVOKED:-0} )); then
    echo "ERR: bar::start not called" >&2
    echo "Exiting.."
    exit 1
  fi
  local -i StepsDone TotalSteps

  ((StepsDone=$1))
  ((TotalSteps=$2))

  if ! __status_changed "$StepsDone" "$TotalSteps"; then
    return 1
  fi
  
  __draw_status_line
  return $?
}


####################################################


# This section defines some functions that should be
# triggered for traps
# ==================================================


handle_sigwinch(){
  __tty_size
  n_rows=$HEIGHT
  __change_scroll_area "$n_rows"
  __draw_status_line
}

handle_exit(){
  #-- if stop_exit doesn't have value it means it wasn't invoked
  (( ! ${E_STOP_INVOKED:-0} )) && bar::stop
  trap - EXIT
}


####################################################

set +a

trap handle_sigwinch WINCH
trap handle_exit EXIT HUP INT QUIT PIPE TERM