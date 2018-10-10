#!/bin/bash
services=(cinder-api cinder-volume cinder-scheduler)

function main() {
	case $1 in
		start)
			[[ "$2" != "" ]] && { start_service $2; return; }
			;;
		stop)
			[[ "$2" != "" ]] && { stop_service $2; return; }
			;;
		list)
			echo cinder-api
			echo cinder-volume
			echo cinder-scheduler
			;;
		status)
			[[ $2 != "" ]] && {
				echo -n "$2: "; pidof $2;return
			}
			for s in "${services[@]}";do
				echo -n "$s: "; pidof $s
			done
			;;
	esac
}

function pidof() {
	local name=$1
	local pids=()
	for f in /proc/*/comm; do
		read comm <$f
		[[ $comm == "${name::15}" ]] && {
			tmp=${f#/proc/};pids=( ${pids[@]} ${tmp%/comm})
		}
	done
	echo ${pids[@]}
}

function start_service() {

	local name=$1
	local i=0
	case $name in
		cinder-api)
			echo -n starting $name " ..."
			nohup sudo -u cinder /usr/bin/cinder-api --config-file /usr/share/cinder/cinder-dist.conf --config-file /etc/cinder/cinder.conf --logfile /var/log/cinder/api.log &>/dev/null &
			while !curl http://localhost:8776 &>/dev/null; do
				((i++)); [[ $i -gt 20 ]] && break
				sleep 0.3
			done
		;;
		cinder-volume)
			echo -n starting $name " ..."
			nohup sudo -u cinder /usr/bin/cinder-volume --config-file /usr/share/cinder/cinder-dist.conf --config-file /etc/cinder/cinder.conf --logfile /var/log/cinder/volume.log &>/dev/null &
		;;
		cinder-scheduler)
			echo -n starting $name " ..."
			nohup sudo -u cinder /usr/bin/cinder-scheduler --config-file /usr/share/cinder/cinder-dist.conf --config-file /etc/cinder/cinder.conf --logfile /var/log/cinder/scheduler.log &>/dev/null &
		;;
		*)
			echo service is not exists; return
	esac
	if [[ $i -gt 20 ]]; then
		echo "    Timeout"; return
	fi
	echo "    Succ"
}

function stop_service() {

	local name=$1
	case $name in
		cinder-api|cinder-volume|cinder-scheduler)
			echo -n stopping $name "   "
			while killall $name &>/dev/null; do echo -n .; sleep 0.1; done
			echo "    Succ"
		;;
		*)
			echo service is not exists;
	esac
}


main "$@"
