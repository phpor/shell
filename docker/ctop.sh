#!/bin/bash
CGROUP_DIR=/sys/fs/cgroup
UNLIMITTED=9223372036854771712
SC_CLK_TCK=$(getconf CLK_TCK)
NANOSECONDSPERSECOND=1000000000
COMMAND=comm

function main() {
	trap quit 2 3 15
	get_cpu_info_raw
	tput civis
	sleep 0.3

	while :; do
		tput clear
		get_cpu_info
		get_mem_info
		echo
		get_process_info
		unset char
		read -s -N 1 -t 1 char
		[[ $char == "q" ]] && break
		[[ $char == "c" ]] && { [[ $COMMAND == comm ]] && COMMAND=cmdline || COMMAND=comm; }
	done
	quit
}

function quit() {
	tput cnorm
	exit 0
}

function get_cpu_info() {
	get_cpu_info_raw

	local total_usage=$((total_usage - last_total_usage))
	local cpu_system_usage=$((cpu_system_usage - last_cpu_system_usage))
	local cpu_percent_10=$((10*total_usage/(cpu_system_usage/100)*cpu_num/restricted_cpu_num))

	printf "%12s %13d.%d%%\n" "Cpu(s):" $((cpu_percent_10/10)) $((cpu_percent_10%10))
}

function get_cpu_info_raw() {
	last_cpu_num=$cpu_num last_restricted_cpu_num=$restricted_cpu_num
	last_total_usage=$total_usage last_cpu_system_usage=$cpu_system_usage
        last_cpu_cfs_quota_us=$cpu_cfs_quota_us last_cpu_cfs_period_us=$cpu_cfs_period_us
	last_cpu_usage_system=$cpu_usage_system last_cpu_usage_user=$cpu_usage_user

	read cpu c1 c2 c3 c4 c5 c6 c7 _ </proc/stat
	cpu_system_usage=$(( (c1+c2+c3+c4+c5+c6+c7) * (NANOSECONDSPERSECOND / SC_CLK_TCK) ))
	read cpu_cfs_quota_us <$CGROUP_DIR/cpuacct/cpu.cfs_quota_us
	read cpu_cfs_period_us <$CGROUP_DIR/cpuacct/cpu.cfs_period_us
	read -a cpu_usage_percpu <$CGROUP_DIR/cpuacct/cpuacct.usage_percpu
	cpu_num=${#cpu_usage_percpu[@]}


        if [[ $cpu_cfs_quota_us == -1 ]]; then # no cpu limit
            restricted_cpu_num=$cpu_num
        else
            restricted_cpu_num=$((cpu_cfs_quota_us / cpu_cfs_period_us))
	fi

	read total_usage <$CGROUP_DIR/cpuacct/cpuacct.usage
	while read k v; do
		[[ $k == "user" ]] && cpu_usage_user=$v
		[[ $k == "system" ]] && cpu_usage_system=$v
	done<$CGROUP_DIR/cpuacct/cpuacct.usage

}

# Finds CPU time of all processes named $1.
# Disclaimer: I am not a shell programmer.
function getcputime() {
    local proc=$1
    local clk_tck=SC_CLK_TCK
    local cputime=0
    local pids=$(pidof $proc)
    for pid in $pids;
    do
        local stats=$(cat "/proc/$pid/stat")
        local statarr=($stats)
        local utime=${statarr[13]}
        local stime=${statarr[14]}
        cputime=$(bc <<< "scale=3; $cputime + $utime / $clk_tck + $stime / $clk_tck")
    done
    echo $cputime
}

function get_mem_info() {
	read mem_total <$CGROUP_DIR/memory/memory.limit_in_bytes
	read mem_used <$CGROUP_DIR/memory/memory.usage_in_bytes
	mem_free=$((mem_total - mem_used))

	read mem_swap_total <$CGROUP_DIR/memory/memory.memsw.limit_in_bytes
	read mem_swap_used <$CGROUP_DIR/memory/memory.memsw.usage_in_bytes
	swap_total=$((mem_swap_total - mem_total))
	swap_used=$((mem_swap_used - mem_used))
	swap_free=$((swap_total - swap_used))
	printf "%12s%16s total, %20s used, %20s free\n" "Mem(MB):" $((mem_total/1024/1024)) $((mem_used/1024/1024)) $((mem_free/1024/1024))
	printf "%12s%16s total, %20s used, %20s free\n"  "Swap(MB):" $((swap_total/1024/1024)) $((swap_used/1024/1024)) $((swap_free/1024/1024))
}

function get_process_info() {
	local pids=$(get_process_pids)
	printf "%8s%8s%8s%8s %s\n" PID PPID TGID "RSS(KB)" COMMAND
	local count=0
	for pid in $pids; do
		[[ ! -e /proc/$pid ]] && continue
		while read k v _;do
			case $k in
				"PPid:") ppid=$v;;
				"Tgid:") tgid=$v;;
				"VmRSS:") rss=$v;;
			esac
		done</proc/$pid/status
		cmd=$(</proc/$pid/$COMMAND)
		printf "%8s%8s%8s%8s %s\n" $pid $ppid $tgid $rss $cmd
		((count++))
	done
	printf "\nProcess(%s)\n" $count
}


function get_process_pids() {
	for d in /proc/*;do
		[[ $d =~ /proc/[0-9]+ ]] && echo ${d#/proc/}
	done
}
main
