blue_color="\e[34m"
reset_color="\e[0m"

function log_info {
	printf "%b%s%b%s\n" "${blue_color}" "INFO: " "${reset_color}" "${1}"
}
