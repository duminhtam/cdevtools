dd#!/usr/bin/env bash

# rmate
# init
# 
function hostname_command(){
    if hash hostname 2>/dev/null; then
        echo "hostname"
    else {
		HOSTNAME_DESCRIPTOR="/proc/sys/kernel/hostname"
		if test -r "$HOSTNAME_DESCRIPTOR"; then
	        echo "cat $HOSTNAME_DESCRIPTOR"
		else
			echo "hostname"
		fi
		}
    fi
}
hostname_=$(hostname_command)
hostname=`$hostname_`
filepath=""

host="${RMATE_HOST:-localhost}"
port="${RMATE_PORT:-52698}"
selection=""
displayname=""
filetype=""
verbose=false
nowait=true
force=false

# process command-line parameters
#
function showusage {
    echo "usage: $0 [-H host-name] [-p port-number] [-w] [-l line-number] [-m display-name] [-t file-type] [-f] [-v] file-path

-H  connect to host (default: $host)
-p  port number to use for connection (default: $port)
-w  wait for file to be closed by TextMate
-l  place caret on line number after loading file
-m  the display name shown in TextMate
-t  treat file as having specified type
-f  open even if file is not writable
-v  verbose logging messages
-h  display this usage information
"
}

function log {
    if [[ $verbose = true ]]; then
        echo "$@" 1>&2
    fi
}

while getopts H:p:wl:m:t:fvh OPTIONS; do
    case $OPTIONS in
        H)
            host=$OPTARG;;
        p)
            port=$OPTARG;;
        w) 
            nowait=false;;
        l)
            selection=$OPTARG;;
        m)
            displayname=$OPTARG;;
        t)
            filetype=$OPTARG;;
        f)
            force=true;;
        v)
            verbose=true;;
        h)
            showusage
            exit 1;;
        ?)
            showusage
            exit 1;;
        *)
            showusage
            exit 1;;
    esac
done

filepath="${@:$OPTIND}"

if [ "$filepath" = "" ]; then
    showusage
    exit 1
fi

realpath="`cd \`dirname "$filepath"\`; pwd -P`/$filepath"

if [ -f "$filepath" ] && [ ! -w "$filepath" ]; then
    if [[ $force = false ]]; then
        echo "File $filepath is not writable! Use -f to open anyway."
        exit 1
    elif [[ $verbose = true ]]; then
        log "File $filepath is not writable! Opening anyway."
    fi
fi

if [ "$displayname" = "" ]; then
    displayname="$hostname:$filepath"
fi

#------------------------------------------------------------
# main
#------------------------------------------------------------
function handle_connection {
    local cmd
    local name
    local value
    local token
    local tmp
    
    while read 0<&3; do
        REPLY="${REPLY#"${REPLY%%[![:space:]]*}"}"
        REPLY="${REPLY%"${REPLY##*[![:space:]]}"}"

        cmd=$REPLY

        token=""
        tmp=""

        while read 0<&3; do
            REPLY="${REPLY#"${REPLY%%[![:space:]]*}"}"
            REPLY="${REPLY%"${REPLY##*[![:space:]]}"}"

            if [ "$REPLY" = "" ]; then
                break
            fi
            
            name="${REPLY%%:*}"
            value="${REPLY##*:}"
            value="${value#"${value%%[![:space:]]*}"}"      # fix textmate syntax highlighting: "
                        
            case $name in
                "token")
                    token=$value
                    ;;
                "data")
                    if [ "$tmp" = "" ]; then
                        tmp="/tmp/rmate.$RANDOM.$$"
                        touch "$tmp"
                    fi
                
                    dd bs=1 count=$value <&3 >>"$tmp" 2>/dev/null
                    ;;
                *)
                    ;;
            esac
        done

        if [[ "$cmd" = "close" ]]; then
            log "Closing $token"
        elif [[ "$cmd" = "save" ]]; then
            log "Saving $token"

            cat "$tmp" >  "$token"
            rm "$tmp"		
        fi
    done
    
    log "Done"
}

# connect to textmate and send command
#
exec 3<> /dev/tcp/$host/$port

if [ $? -gt 0 ]; then
	echo "Unable to connect to TextMate on $host:$port"
	exit 1
fi

read server_info 0<&3

log $server_info

echo "open" 1>&3
echo "display-name: $displayname" 1>&3
echo "real-path: $realpath" 1>&3
echo "data-on-save: yes" 1>&3
echo "re-activate: yes" 1>&3
echo "token: $filepath" 1>&3

if [ "$selection" != "" ]; then
    echo "selection: $selection" 1>&3
fi

if [ "$filetype" != "" ]; then
    echo "file-type: $filetype" 1>&3
fi

if [ -f "$filepath" ]; then
    filesize=`ls -l "$filepath" | awk '{print $5}'`
    echo "data: $filesize" 1>&3
    cat "$filepath" 1>&3
else
    echo "data: 0" 1>&3
fi

echo 1>&3
echo "." 1>&3

if [[ $nowait = true ]]; then
    exec </dev/null >/dev/null 2>/dev/null
    ( (handle_connection &) &)
else
    handle_connection
fi

