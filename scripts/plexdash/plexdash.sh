#!/bin/bash

command -v dialog &>/dev/null || { echo "dialog is required but not installed. Run: sudo apt install dialog"; exit 1; }

# ── Configuration ──────────────────────────────────────────────────────────────
TITLE="Plex Media Server Dashboard"

PLEX_CONTAINER="plex"
PLEX_PORT=32400
PLEX_CONFIG_DIR="/srv/plex/config"
PLEX_MEDIA_DIR="/srv/plex/media"
DOWNLOADS_DIR="/srv/downloads"
MEDIA_SUBDIRS=("Movies" "TV")
COMPOSE_FILE="docker-compose.yml"

declare -A containers=(
    [plex]="Plex Media Server"
    [qbittorrent]="qBittorrent Client"
    [radarr]="Radarr Movie Manager"
    [sonarr]="Sonarr TV Manager"
    [jackett]="Jackett Indexer"
)

declare -A compose_dirs=(
    [plex]="/srv/plex"
    [qbittorrent]="/srv/qbittorrent"
    [radarr]="/srv/radarr"
    [sonarr]="/srv/sonarr"
    [jackett]="/srv/jackett"
)
# ───────────────────────────────────────────────────────────────────────────────

PLEX_TOKEN=$(grep -oP 'PlexOnlineToken="\K[^"]+' \
    "$PLEX_CONFIG_DIR/Library/Application Support/Plex Media Server/Preferences.xml" 2>/dev/null)

get_plex_streams() {
    [ -z "$PLEX_TOKEN" ] && echo "?" && return
    local count
    count=$(curl -s -m 2 \
        "http://localhost:${PLEX_PORT}/status/sessions?X-Plex-Token=$PLEX_TOKEN" 2>/dev/null \
        | grep -oP 'size="\K[0-9]+' | head -1)
    echo "${count:-0}"
}

get_status() {
    local container=$1
    local line
    line=$(echo "$CONTAINER_DATA" | grep "^${container}|")
    if [ -n "$line" ]; then
        local status_text="${line#*|}"
        local uptime="${status_text#Up }"
        echo "\Z2[Running - $uptime]\Zn"
    else
        echo "\Z1[Stopped]\Zn"
    fi
}

get_resource_usage() {
    local container=$1
    local stats
    stats=$(docker stats --no-stream --format "{{.CPUPerc}}|{{.MemUsage}}" "$container" 2>/dev/null)
    if [ -n "$stats" ]; then
        IFS='|' read -r cpu mem <<< "$stats"
        echo "CPU: $cpu, RAM: $mem"
    else
        echo "Not running"
    fi
}

get_ports() {
    local container=$1
    local ports
    ports=$(docker port "$container" 2>/dev/null)
    if [ -n "$ports" ]; then
        echo "$ports"
    else
        echo "No ports exposed"
    fi
}

manage_container() {
    local container=$1

    ACTION=$(dialog --clear --backtitle "$TITLE" \
        --title "Manage $container" \
        --menu "Select an action for '$container':" 15 50 8 \
        1 "Resource Usage" \
        2 "Start" \
        3 "Stop" \
        4 "Restart" \
        5 "Status" \
        6 "Ports" \
        7 "View Logs" \
        8 "Back" \
        3>&1 1>&2 2>&3)

    clear

    case $ACTION in
        1)
            local usage
            usage=$(get_resource_usage "$container")
            dialog --msgbox "Resource Usage:\n\n$usage" 10 50
            ;;
        2)
            docker start "$container" 2>&1 | dialog --progressbox "Starting $container..." 10 50
            ;;
        3)
            docker stop "$container" 2>&1 | dialog --progressbox "Stopping $container..." 10 50
            ;;
        4)
            docker restart "$container" 2>&1 | dialog --progressbox "Restarting $container..." 10 50
            ;;
        5)
            local status
            status=$(docker ps -a --filter "name=$container" --format "{{.Names}} - {{.Status}}")
            dialog --msgbox "Status:\n\n$status" 10 50
            ;;
        6)
            local ports
            ports=$(get_ports "$container")
            dialog --msgbox "Ports:\n\n$ports" 15 60
            ;;
        7)
            local tmpfile
            tmpfile=$(mktemp)
            docker logs --tail 50 -f "$container" > "$tmpfile" 2>&1 &
            local LOG_PID=$!
            dialog --title "Logs: $container (press Q to exit)" --tailbox "$tmpfile" 30 100
            kill "$LOG_PID" 2>/dev/null
            rm -f "$tmpfile"
            ;;
        *)
            return
            ;;
    esac

    sleep 1
}

# Pulls all images, populates PULL_UPDATED and PULL_CURRENT arrays
do_pull_with_summary() {
    declare -A pre_ids
    for container in "${!compose_dirs[@]}"; do
        pre_ids[$container]=$(docker inspect --format '{{.Image}}' "$container" 2>/dev/null)
    done

    (for container in "${!compose_dirs[@]}"; do
        echo "==> Pulling $container..."
        docker compose -f "${compose_dirs[$container]}/$COMPOSE_FILE" pull 2>&1
    done) | dialog --progressbox "Pulling latest images..." 20 70

    PULL_UPDATED=()
    PULL_CURRENT=()
    for container in "${!compose_dirs[@]}"; do
        local image_name new_id
        image_name=$(docker inspect --format '{{.Config.Image}}' "$container" 2>/dev/null)
        new_id=$(docker image inspect --format '{{.Id}}' "$image_name" 2>/dev/null)
        if [[ -n "$new_id" && "${pre_ids[$container]}" != "$new_id" ]]; then
            PULL_UPDATED+=("$container")
        else
            PULL_CURRENT+=("$container")
        fi
    done
}

quick_actions() {
    ACTION=$(dialog --clear --backtitle "$TITLE" \
        --title "Quick Actions" \
        --menu "Select a quick action:" 15 55 5 \
        1 "Restart All Containers" \
        2 "Check for Updates" \
        3 "Update and Restart Updated" \
        4 "Prune Old Containers/Images" \
        5 "Back" \
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
            do_pull_with_summary
            local summary=""
            for c in "${PULL_UPDATED[@]}"; do summary+="  [UPDATED]  $c\n"; done
            for c in "${PULL_CURRENT[@]}"; do summary+="  [current]  $c\n"; done
            dialog --msgbox "Pull complete:\n\n${summary}" 15 50
            ;;
        3)
            do_pull_with_summary
            local summary=""
            for c in "${PULL_UPDATED[@]}"; do summary+="  [UPDATED]  $c\n"; done
            for c in "${PULL_CURRENT[@]}"; do summary+="  [current]  $c\n"; done
            if [ ${#PULL_UPDATED[@]} -gt 0 ]; then
                dialog --yesno "Pull complete:\n\n${summary}\nRestart ${#PULL_UPDATED[@]} updated container(s)?" 15 55
                if [ $? -eq 0 ]; then
                    (for c in "${PULL_UPDATED[@]}"; do
                        echo "Restarting $c..."
                        docker compose -f "${compose_dirs[$c]}/$COMPOSE_FILE" up -d 2>&1
                    done) | dialog --progressbox "Restarting updated containers..." 15 70
                fi
            else
                dialog --msgbox "Pull complete:\n\n${summary}\nAll containers are already up to date." 12 50
            fi
            ;;
        4)
            dialog --yesno "This will delete ALL unused images and containers.\nThis cannot be undone. Continue?" 8 60
            if [ $? -eq 0 ]; then
                (docker system prune -af) | dialog --progressbox "Pruning old containers/images..." 20 70
                dialog --msgbox "Prune complete." 8 40
            fi
            ;;
        *)
            return
            ;;
    esac
}

disk_usage() {
    local downloads_vol media_vol root_vol dl_used subdir_lines=""
    downloads_vol=$(df -h "$DOWNLOADS_DIR" | awk 'NR==2 {printf "%-18s %6s / %-6s (%s)", $1, $3, $2, $5}')
    media_vol=$(df -h "$PLEX_MEDIA_DIR"    | awk 'NR==2 {printf "%-18s %6s / %-6s (%s)", $1, $3, $2, $5}')
    root_vol=$(df -h /                     | awk 'NR==2 {printf "%-18s %6s / %-6s (%s)", $1, $3, $2, $5}')
    dl_used=$(du -sh "$DOWNLOADS_DIR" 2>/dev/null | awk '{print $1}')

    for subdir in "${MEDIA_SUBDIRS[@]}"; do
        local used
        used=$(du -sh "$PLEX_MEDIA_DIR/$subdir" 2>/dev/null | awk '{print $1}')
        subdir_lines+="  $(printf '%-10s' "$subdir")  ${used:-n/a}\n"
    done

    dialog --title "Disk Usage" --msgbox "\
Volumes:
  Downloads   $downloads_vol
  Media       $media_vol
  Root        $root_vol

Media breakdown:
${subdir_lines}
Downloads (in progress):
  Total       ${dl_used:-n/a}
" 18 70
}

landing_page() {
    local uptime load mem disk
    uptime=$(uptime -p)
    load=$(uptime | awk -F'load average:' '{ print $2 }')
    mem=$(free -h | awk '/Mem:/ {print $3 "/" $2}')
    disk=$(df -h / | awk 'NR==2 {print $3 "/" $2 " (" $5 ")"}')

    dialog --msgbox "$TITLE\n\nSystem Stats:\n Uptime: $uptime\n Load: $load\n Memory: $mem\n Disk: $disk" 14 60
}

landing_page
while true; do
    CONTAINER_DATA=$(docker ps --format '{{.Names}}|{{.Status}}')

    menu_items=()
    for container in "${!containers[@]}"; do
        local_status=$(get_status "$container")
        label="${containers[$container]} $local_status"
        if [[ "$container" == "$PLEX_CONTAINER" ]]; then
            streams=$(get_plex_streams)
            label="$label | ${streams} stream(s)"
        fi
        menu_items+=("$container" "$label")
    done
    menu_items+=("QuickActions" "Quick Actions")
    menu_items+=("Disk" "Disk Usage")
    menu_items+=("Exit" "Exit dashboard")

    CHOICE=$(dialog --clear --backtitle "$TITLE" \
        --title "Plex Dashboard" \
        --colors \
        --menu "Select a service to manage:" 20 70 12 \
        "${menu_items[@]}" \
        3>&1 1>&2 2>&3)

    clear

    [[ "$CHOICE" == "Exit" || -z "$CHOICE" ]] && break

    if [[ "$CHOICE" == "QuickActions" ]]; then
        quick_actions
    elif [[ "$CHOICE" == "Disk" ]]; then
        disk_usage
    else
        manage_container "$CHOICE"
    fi
done
