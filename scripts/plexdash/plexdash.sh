#!/bin/bash

# Title
TITLE="Plex Media Server Dashboard"

# List of containers and their friendly names
declare -A containers=(
  [plex]="Plex Media Server"
  [qbittorrent]="qBittorrent Client"
  [radarr]="Radarr Movie Manager"
  [sonarr]="Sonarr TV Manager"
  [jackett]="Jackett Indexer"
)

# Function to get running status
get_status() {
    local container=$1
    if docker ps --format '{{.Names}}' | grep -q "^${container}$"; then
        echo "\Z2[Running]\Zn"
    else
        echo "\Z1[Stopped]\Zn"
    fi
}

# Function to get resource usage
get_resource_usage() {
    local container=$1
    stats=$(docker stats --no-stream --format "{{.CPUPerc}}|{{.MemUsage}}" "$container" 2>/dev/null)
    if [ -n "$stats" ]; then
        IFS='|' read -r cpu mem <<< "$stats"
        echo "CPU: $cpu, RAM: $mem"
    else
        echo "Not running"
    fi
}

# Function to get ports
get_ports() {
    local container=$1
    ports=$(docker port "$container" 2>/dev/null)
    if [ -n "$ports" ]; then
	echo "$ports"
    else
	echo "No ports exposed"
    fi
}

# Function to manage a container
manage_container() {
    local container=$1

    ACTION=$(dialog --clear --backtitle "$TITLE" \
        --title "Manage $container" \
        --menu "Select an action for '$container':" 15 50 6 \
	1 "Resource Usage" \
        2 "Start" \
        3 "Stop" \
        4 "Restart" \
        5 "Status" \
        6 "Ports" \
	7 "Back" \
        3>&1 1>&2 2>&3)

    clear

    case $ACTION in
        1)
            usage=$(get_resource_usage "$container")
            dialog --msgbox "Resource Usage:\n\n$usage" 10 50
            ;;
	2)
            docker start "$container" && echo "'$container' started successfully."
            ;;
        3)
            docker stop "$container" && echo "'$container' stopped successfully."
            ;;
        4)
            docker restart "$container" && echo "'$container' restarted successfully."
            ;;
        5)
            status=$(docker ps -a --filter "name=$container" --format "{{.Names}} - {{.Status}}")
            dialog --msgbox "Status:\n\n$status" 10 50
	    ;;
	6)
	    ports=$(get_ports "$container")
	    dialog --msgbox "Ports:\n\n$ports" 15 60
	    ;;
        *)
            return
            ;;
    esac

    sleep 1
}

# Function for quick actions
quick_actions() {
    ACTION=$(dialog --clear --backtitle "$TITLE" \
	--title "Quick Actions" \
	--menu "Select a quick action:" 15 50 5 \
	1 "Restart All Containers" \
	2 "Check for Updates (docker compose pull)" \
	3 "Prune Old Containers/Images" \
	4 "Back" \
	3>&1 1>&2 2>&3)

    clear

    case $ACTION in
	1)
	    for container in "${!containers[@]}"; do
	        docker restart "$container"
	    done
	    dialog --msgbox "All containers restarted successfully." 8 50
	    ;;
	2)
	    (docker compose pull) | dialog --progressbox "Checking for updates..." 20 70
	    dialog --msgbox "Update check complete." 8 40
	    ;;
	3)
	    (docker system prune -af) | dialog --progressbox "Pruning old containers/images..." 20 70
	    dialog --msgbox "Prune complete." 8 40
	    ;;
	*)
	    return
	    ;;
	esac
}


# Landing page with system stats and ASCII banner
landing_page() {
    banner="$TITLE"
    uptime=$(uptime -p)
    load=$(uptime | awk -F'load average:' '{ print $2 }')
    mem=$(free -h | awk '/Mem:/ {print $3 "/" $2}')
    disk=$(df -h / | awk 'NR==2 {print $3 "/" $2 " (" $5 ")"}')

    dialog --msgbox "${banner}\n\nSystem Stats:\n Uptime: $uptime\n Load: $load\n Memory: $mem\n Disk: $disk" 20 70
}

# Main loop
# landing_page
while true; do
    # Dynamically build menu items with status
    menu_items=()
    for container in "${!containers[@]}"; do
	status=$(get_status "$container")
	menu_items+=("$container" "${containers[$container]} $status")
    done
    menu_items+=("QuickActions" "Quick Actions")
    menu_items+=("Exit" "Exit dashboard")

    CHOICE=$(dialog --clear --backtitle "$TITLE" \
        --title "Plex Dashboard" \
	--colors \
        --menu "Select a service to manage:" 20 60 12 \
        "${menu_items[@]}" \
        3>&1 1>&2 2>&3)

    clear

    [[ "$CHOICE" == "Exit" || -z "$CHOICE" ]] && break

    if [[ "$CHOICE" == "QuickActions" ]]; then
	quick_actions
    else
	manage_container "$CHOICE"
    fi
done
