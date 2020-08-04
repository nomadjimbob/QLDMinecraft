#!/bin/sh

#############################################
# Configration Options
#############################################
PAPER_TARGET_VERSION="0"
PAPER_LAST_BUILD="0"
MINECRAFT_DIR="/etc/spigot/"
MINECRAFT_JAR="paper.jar"
WWW_DIR="/var/www/map.qldminecraft.com.au/"
LOG_FILE="logs/latest.log"
SCREEN_NAME="spigot"
SCREEN_CMD="java -Xms12G -Xmx12G -XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 -XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC -XX:+AlwaysPreTouch -XX:G1NewSizePercent=30 -XX:G1MaxNewSizePercent=40 -XX:G1HeapRegionSize=8M -XX:G1ReservePercent=20 -XX:G1HeapWastePercent=5 -XX:G1MixedGCCountTarget=4 -XX:InitiatingHeapOccupancyPercent=15 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:SurvivorRatio=32 -XX:+PerfDisableSharedMem -XX:MaxTenuringThreshold=1 -Dusing.aikars.flags=https://mcflags.emc.gs -Daikars.new.flags=true -jar "${MINECRAFT_DIR}${MINECRAFT_JAR}" nogui"
MSG_CMD="ex narrate format:serverchat %s targets:<server.online_players>"
#MSG_CMD="ex actionbar format:servernotice %s targets:<server.online_players>"




CMD_START=0
CMD_RESTART=0
CMD_STOP=0
CMD_ROTATE=0
CMD_BACKUP=0
CMD_UPDATE=0
CMD_VERSION=0
CMD_VERSION_DATA="get"
CMD_LAST_BUILD=0
CMD_DELAY=10


minecraft_update()
{
    if [ -n "$(ps -ef | grep -i "screen .* ${SCREEN_NAME}" | grep -v 'grep')" ]; then
        minecraft_stop

        if [ $CMD_STOP -eq 0 ]; then
            CMD_START=1
        fi
    fi

    cd "${MINECRAFT_DIR}"
    jenkins_download "Paper" "https://papermc.io/ci/job/Paper-1.16/"
    if [ ! "${FILE_DOWNLOAD}" = "" ]; then
        if [ -f "paper.jar" ]; then
            rm "paper.jar"
        fi

        cp "${FILE_DOWNLOAD}" "paper.jar"
    fi

    cd "${MINECRAFT_DIR}plugins/"
    jenkins_download "ProtocolLib" "https://ci.dmulloy2.net/job/ProtocolLib/"
    jenkins_download "MultiversePortals" "http://ci.onarandombox.com/job/Multiverse-Portals/" -3
    jenkins_download "MultiverseCore" "https://ci.onarandombox.com/job/Multiverse-Core/" -3
    jenkins_download "LuckPerms" "https://ci.lucko.me/job/LuckPerms/" "bukkit"
    jenkins_download "Floodgate" "https://ci.nukkitx.com/job/GeyserMC/job/Floodgate/job/development/" "bukkit"
    jenkins_download "Geyser" "https://ci.nukkitx.com/job/GeyserMC/job/Geyser/job/master/" "spigot"
    jenkins_download "EssentialsX" "https://ci.ender.zone/job/EssentialsX/"
    jenkins_download "Depenizen" "https://ci.citizensnpcs.co/job/Depenizen/"
    jenkins_download "Denizen" "https://ci.citizensnpcs.co/job/Denizen_Developmental/"
    jenkins_download "Citizens2" "https://ci.citizensnpcs.co/job/Citizens2/"
    jenkins_download "ViaBackwards" "https://ci.viaversion.com/job/ViaBackwards/"
    jenkins_download "ViaVersion" "https://ci.viaversion.com/job/ViaVersion/"
}


jenkins_download()
{
    printf "Checking updates for ${1}"

    BUILD_INSTALLED=0
    FILE_INSTALLED=""

    if [ -f "${1}.txt" ]; then
        BUILD_INSTALLED=$(cat "${1}.txt" | cut -f1 -d'|')
        FILE_INSTALLED=$(cat "${1}.txt" | cut -f2 -d'|')

        echo " (build ${BUILD_INSTALLED} installed)"
    else
        echo " (Not installed by updater)"
    fi

    DETAIL=$(wget -q -O - "${2}lastSuccessfulBuild/api/xml?tree=artifacts[relativePath],id")

    if [ -n "${3}" ]; then
        if [ $(echo "${3}" | head -c 1) = "-" ]; then
            BUILD_DOWNLOAD=$(echo "${DETAIL}" | xpath -q -e '(//id/text())[1]')
            IDX=$(echo "${3}" | tail -c +2)
            RELATIVE_PATH=$(echo "${DETAIL}" | xpath -q -e "(//relativePath/text())[${IDX}]")
            if [ -z "${RELATIVE_PATH}" ]; then
                echo "   Branch ${3} not found"
                return
            fi
        else
            IDX=1
            BUILD_DOWNLOAD=$(echo "${DETAIL}" | xpath -q -e '(//id/text())[1]')

            while [ $IDX -ne 0 ]; do
                RELATIVE_PATH=$(echo "${DETAIL}" | xpath -q -e "(//relativePath/text())[${IDX}]")
                if [ -z "${RELATIVE_PATH}" ]; then
                    IDX=0
                    echo "   Branch ${3} not found"
                    return
                else
                    if [ ! $(echo "${RELATIVE_PATH}" | grep -i "${3}") = "" ]; then
                        IDX=0
                    else
                        IDX=$((${IDX}+1))
                    fi
                fi
            done
        fi
    else
        RELATIVE_PATH=$(echo "${DETAIL}" | xpath -q -e '(//relativePath/text())[1]')
        BUILD_DOWNLOAD=$(echo "${DETAIL}" | xpath -q -e '(//id/text())[1]')
    fi    
    
    printf "   Latest build: ${BUILD_DOWNLOAD}"

    if [ ${BUILD_DOWNLOAD} -gt ${BUILD_INSTALLED} ]; then
        if [ -f "${FILE_INSTALLED}" ]; then
            if [ -f "${FILE_INSTALLED}.bak" ]; then
                rm "${FILE_INSTALLED}.bak"
            fi
            mv "${FILE_INSTALLED}" "${FILE_INSTALLED}.bak"
        fi
        printf "   Downloading update..."
        URL="${2}lastSuccessfulBuild/artifact/${RELATIVE_PATH}"
        wget -q -N - "${URL}"
        FILE_DOWNLOAD=$(basename "${URL}")

        echo "${BUILD_DOWNLOAD}|${FILE_DOWNLOAD}" > "${1}.txt"
        echo "   Installed"
    else
        echo " (Skipped)"
    fi
}


script_usage()
{
    echo "Minecraft script by James Collins"
    echo ""
    echo "Usage: minecraft [ -options ]"
    echo ""
    echo "Options:"
    echo ""
    echo "-s --start         Start Minecraft server"
    echo "-r --restart       Restart Minecraft server"
    echo "-x --stop          Stop Minecraft server"
    echo "-b --backup        Backup Minecraft server files and config"
    echo "-u --update        Update Minecraft Jar"
    echo "-v --version  [ get | list | value ] Get the current, list available, or set the version target"
    echo "-i --build    Get the last build installed by this script"
    echo "-m --message  show message"
    echo "-c --cmd      run command on server"
    echo "-d --delay    Server stop/restart delay in minutes. Default 10"
}


minecraft_start()
{
    if [ -n "$(ps -ef | grep -i "screen .* ${SCREEN_NAME}" | grep -v 'grep')" ]; then
        echo "Minecraft is already running"
    else
        FLAG_WAITING=1
        FLAG_STARTED=0

        printf "Starting Minecraft on screen '${SCREEN_NAME}'"
        cd "${MINECRAFT_DIR}"
        screen -dmS "${SCREEN_NAME}" ${SCREEN_CMD}

        # Wait for new log
        printf "... Waiting for log"
        NEW_LOG=0
        while [ $NEW_LOG -eq 0 ]
        do
            printf "."
            while [ ! -f "$LOG_FILE" ]
            do
                sleep 1
            done

            if [ "$(grep '\(.*\)Closing Server' "$LOG_FILE")" != "" ]; then
                sleep 1
            else
                NEW_LOG=1
            fi
        done

        LOG_COUNT=$(wc -l "$LOG_FILE" | sed 's/^ *\([0-9]*\).*$/\1/')
        printf " Log created"

        while [ $FLAG_WAITING -eq 1 ]
        do
            sleep 1
            printf "."

            if [ -z "$(ps -ef | grep -i "screen .* ${SCREEN_NAME}" | grep -v 'grep')" ]; then
                FLAG_WAITING=0
            fi

            LOG_TXT=$(tail -n +$LOG_COUNT $LOG_FILE)
            if [ "$LOG_TXT" != "" ]; then
                if [ "$(echo "$LOG_TXT" | grep -in 'Done \(.*\)! For help, type "help"')" != "" ]; then
                    FLAG_WAITING=0
                    FLAG_STARTED=1
                fi
                LOG_COUNT=$(($LOG_COUNT+$(echo "$LOG_TXT" | wc -l | sed 's/^ *\([0-9]*\).*$/\1/')))
            fi
        done

        if [ $FLAG_STARTED -eq 0 ]; then
            echo " Error"
            echo "Check the logs for more info"
        else
            printf " Copying dynmap www files..."
            cp -r "${MINECRAFT_DIR}plugins/dynmap/web/"* "${WWW_DIR}"
            echo " Done"
        fi
    fi
}


minecraft_stop()
{
    if [ -n "$(ps -ef | grep -i "screen .* ${SCREEN_NAME}" | grep -v 'grep')" ]; then
        if [ $CMD_DELAY -ne 0 ]; then
            TIMER=$CMD_DELAY
            
            STOP_MESSAGE="Server shutdown in %i minutes"

            while [ $TIMER -gt 0 ];
            do
                SHOW_MESSAGE=$(echo "${STOP_MESSAGE}" | sed "s/%i/${TIMER}/g")
                minecraft_message "${SHOW_MESSAGE}"
                sleep 60
                TIMER=$(($TIMER-1))
            done
        fi

        printf "Stopping Minecraft"
        screen -p 0 -S "${SCREEN_NAME}" -X eval "stuff stop\015"
        while [ -n "$(ps -ef | grep -i "screen .* ${SCREEN_NAME}" | grep -v 'grep')" ]
        do
            sleep 1
            printf "."
        done
        echo " Done"
    else
        echo "Minecraft not running"
    fi
}


minecraft_backup()
{
    if [ -n "$(ps -ef | grep -i "screen .* ${SCREEN_NAME}" | grep -v 'grep')" ]; then
        minecraft_stop

        if [ $CMD_STOP -eq 0 ]; then
            CMD_START=1
        fi
    fi

    echo "Backing up Minecraft"
    mkdir -p "${MINECRAFT_DIR}backup"

    if [ -d "${MINECRAFT_DIR}backup/tmp" ]; then
        rm -rf "${MINECRAFT_DIR}backup/tmp"
    fi
    
    mkdir -p "${MINECRAFT_DIR}backup/tmp"

    echo "Backing up jar..."
    cp "${MINECRAFT_DIR}${MINECRAFT_JAR}" "${MINECRAFT_DIR}backup/tmp/"

    echo "Backing up configuration files..."
    cp "${MINECRAFT_DIR}"*".properties" "${MINECRAFT_DIR}backup/tmp/"
    cp "${MINECRAFT_DIR}"*".yml" "${MINECRAFT_DIR}backup/tmp/"
    cp "${MINECRAFT_DIR}"*".json" "${MINECRAFT_DIR}backup/tmp/"

    echo "Backing up plugins..."
    cp -r "${MINECRAFT_DIR}plugins" "${MINECRAFT_DIR}backup/tmp/plugins"

    echo "Backing up worlds..."
    cd "${MINECRAFT_DIR}"
    for d in */ ; do
        if [ -f "${MINECRAFT_DIR}${d}/level.dat" ]; then
            echo "  ${d}"
            cp -r "${MINECRAFT_DIR}${d}/" "${MINECRAFT_DIR}backup/tmp/${d}/"
        fi
    done    

    BACKUP_NAME=$(date +"%Y-%m-%d")
    if [ -f "${MINECRAFT_DIR}backup/${BACKUP_NAME}.zip" ]; then
        COUNT=1
        while [ -f "${MINECRAFT_DIR}backup/${BACKUP_NAME}-${COUNT}.zip" ];
        do
            COUNT=$((${COUNT}+1))
        done

        BACKUP_NAME=${BACKUP_NAME}-${COUNT}
    fi

    echo "Compressing Backup... (this may take a few minutes)"
    cd "${MINECRAFT_DIR}backup/tmp/"
    zip -r -q "${MINECRAFT_DIR}backup/${BACKUP_NAME}.zip" *

    echo "Removing temporary files..."
    rm -rf "${MINECRAFT_DIR}backup/tmp"

    echo "Done"
    echo "Backup saved at ${MINECRAFT_DIR}backup/${BACKUP_NAME}.zip"
}


minecraft_version()
{
    if [ "${CMD_VERSION_DATA}" = "get" ]; then
        echo "The current Minecraft Paper version target is ${PAPER_TARGET_VERSION}"
    else
        if [ "${CMD_VERSION_DATA}" = "list" ]; then
            echo "Paper versions available: "
            VERS=$(curl -s "https://papermc.io/api/v1/paper" | jq ".versions[]")
            echo "$VERS"
        else
            sed -i "s/^\(PAPER_TARGET_VERSION *= *\).*/\1\"${CMD_VERSION_DATA}\"/" $0
            PAPER_TARGET_VERSION="${CMD_VERSION_DATA}"
            echo "The current Minecraft Paper version target is now ${PAPER_TARGET_VERSION}"
        fi
    fi
}


minecraft_lastbuild()
{
    echo "The last Minecraft Paper build installed by this script was ${PAPER_LAST_BUILD}"
}


minecraft_latestbuild()
{
    echo "The last Minecraft Paper build installed by this script was ${PAPER_LAST_BUILD}"
}


minecraft_message()
{
    MESSAGE=$(echo "${MSG_CMD}" | sed "s/%s/\"$1\"/g")
    if [ -n "$(ps -ef | grep -i "screen .* ${SCREEN_NAME}" | grep -v 'grep')" ]; then
        screen -p 0 -S "${SCREEN_NAME}" -X stuff "${MESSAGE}\015"
        echo "Message sent to players: $1"
    else
        echo "Minecraft not running"
    fi
}


minecraft_runcmd()
{
    if [ -n "$(ps -ef | grep -i "screen .* ${SCREEN_NAME}" | grep -v 'grep')" ]; then
        screen -p 0 -S "${SCREEN_NAME}" -X stuff "$1\015"
        echo "Command sent to server: $1"
    else
        echo "Minecraft not running"
    fi
}



while [ "$1" != "" ]; do
    case $1 in
        -s | --start )      shift
                            CMD_START=1
                            ;;
        -r | --restart )    shift
                            CMD_RESTART=1
                            ;;
        -x | --stop )       shift
                            CMD_STOP=1
                            ;;
        -b | --backup )     shift
                            CMD_BACKUP=1
                            ;;
        -u | --update )     shift
                            CMD_UPDATE=1
                            ;;
        -v | --version )    shift
                            CMD_VERSION=1
                            if [ -n "$1" ]; then
                                CMD_VERSION_DATA="$1"
                                shift
                            fi
                            ;;
        -l | --last )       shift
                            CMD_LAST_BUILD=1
                            ;;
        -m | --message )    shift
                            if [ -n "$1" ]; then
                                minecraft_message "$1"
                                shift
                            fi
                            ;;
        -d | --delay )      shift
                            if [ -n "$1" ]; then
                                CMD_DELAY="$1"
                                shift
                            fi
                            ;;
        -c | --cmd )        shift
                            if [ -n "$1" ]; then
                                minecraft_runcmd "$1"
                                shift
                            fi
                            ;;
        -h | --help )       script_usage
                            exit
                            ;;
        * )                 script_usage
                            exit 1
    esac
done


if [ $CMD_LAST_BUILD -eq 1 ]; then
    minecraft_lastbuild
fi

if [ $CMD_VERSION -eq 1 ]; then
    minecraft_version
fi

if [ $CMD_STOP -eq 1 ] || [ $CMD_RESTART -eq 1 ]; then
    minecraft_stop
fi

if [ $CMD_BACKUP -eq 1 ]; then
    minecraft_backup
fi

if [ $CMD_UPDATE -eq 1 ]; then
    minecraft_update
fi

if [ $CMD_START -eq 1 ] || [ $CMD_RESTART -eq 1 ]; then
    minecraft_start
fi
