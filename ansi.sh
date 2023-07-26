# ANSI escape code (https://en.wikipedia.org/wiki/ANSI_escape_code)
prefix="\x1b["
suffix="m"
RESET="${prefix}${suffix}"
RED="${prefix}31${suffix}"
GREEN="${prefix}32${suffix}"
CYAN="${prefix}36${suffix}"

print_red() {
  printf "${RED}${1}${RESET}"
}
print_green() {
  printf "${GREEN}${1}${RESET}"
}
print_cyan() {
  printf "${CYAN}${1}${RESET}"
}

error() {
  # printf "${RED}error${RESET}: ${1}\n"
  print_red "error";
  printf ": ${1}\n"
}

