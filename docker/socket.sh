#!/bin/bash
VOLUME_DIR=/data1/docker_volume


function main() {
	export server
	while :; do
		docker ps | awk 'NR>1{print $NF}'|while read name; do
			unixsock=$VOLUME_DIR/$name/config/.control.sock
			is_sock_ok $unixsock && continue
			export name unixsock
			(coproc handler {
				 server
			 }
			 nc -k -U $unixsock -l <&${handler[0]} >&${handler[1]} 2>/dev/null
			)&
		done
		sleep 30
	done
}

function is_sock_ok() {
	unixsock=$1
	[[ -e $unixsock ]] && [[ $(nc -U $unixsock -i 2 <<<ping 2>/dev/null) == "^_^" ]] && return 0
	[[ -e $unixsock ]] && rm -fr $unixsock
	return 1
}

function server() {
	local cmd
	while :; do
		local status=$(docker inspect --format '{{.State.Status}}' $name)
		[[ $status == "exited" ]] && {
			[[ -e $unixsock ]] && unlink $unixsock
			break
		}
		cmd=
		local start=$(date +"%s")
		if ! read -s -t 30 cmd; then
			local end=$(date +"%s")
			[[ -z $cmd ]] && [[ $(( end - start )) -lt 3 ]] && break   # Maybe nc has gone away
			continue
		fi
		case $cmd in
			'start')
				docker start $name
				echo succ
			;;
			'poweroff')
				echo succ
				docker stop $name &
			;;
			'reboot')
				echo succ
				(docker stop $name
				docker start $name )&
			;;
			'ping')
				echo "^_^"
			;;
		esac

	done
}

main
