blue_color="\e[34m"
reset_color="\e[0m"

function log_info {
	printf "%b%s%b\n" "${blue_color}" "${1}" "${reset_color}"
}
