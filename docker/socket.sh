#!/bin/bash
VOLUME_DIR=/data1/docker_volume
MAINSOCKET=/var/run/docker-socket.sock

function main() {
	exec &>/dev/null
	exec </dev/null
	trap quit SIGINT SIGTERM

	local self=$(cd $(dirname $0) && pwd)/$(basename $0)
	local mainsocket=$MAINSOCKET

	while :; do
		docker ps -a | awk 'NR>1{print $NF}'|while read name; do
			local status=$(docker inspect --format '{{.State.Status}}' $name)
			local unixsock=$VOLUME_DIR/$name/config/.control.sock
			if [[ $status == "running" ]];then
				is_sock_ok $unixsock && continue
				nc -k -U $unixsock -l -c "bash $self handler $name" 2>/dev/null &
			else
				[[ -e $unixsock ]] && {
					fuser -k $unixsock &>/dev/null
					rm -fr $unixsock
				}
			fi
		done
		[[ -e $mainsocket ]] && { fuser -k $mainsocket &>/dev/null; rm -fr $mainsocket ;}
		read -t 120 cmd < <(nc -l -U $mainsocket )
	done
}

function is_sock_ok() {
	unixsock=$1
	[[ -e $unixsock ]] && nc -U $unixsock <<<check 2>/dev/null && return 0
}

function server() {
	trap '' SIGPIPE
	local name=$1
	local cmd
	while :; do
		read cmd || exit 0
		case $cmd in
			'start')
				docker-vm start $name
				echo succ
			;;
			'poweroff')
				echo succ
				docker-vm stop $name &>/dev/null &
			;;
			'reboot')
				echo succ
				(docker-vm stop $name
				docker-vm start $name ) &>/dev/null &
			;;
			'ping')
				echo "^_^"
			;;
			'check')
				:
			;;
			'quit'|'q')
				echo "Bye"
				exit 0
			;;
			*)
				echo "Unknown cmd"
			;;
		esac

	done
}

function quit() {
	find $VOLUME_DIR/*/config/.control.sock 2>/dev/null | while read unixsock;do
		fuser -k $unixsock &>/dev/null
		rm -fr $unixsock
	done
	fuser -k $MAINSOCKET
	exit
}

[[ $1 == 'handler' ]] && {
	server $2
	exit
}
main $*
