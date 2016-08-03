#!/bin/bash
function make_tmp_filename() {
	str='abcdefghigklmnopqrstuvwxyz'
	echo .
	for ((i=0; i<=4; i++)); {
		echo ${str:$($RANDOM % 26)}
	}
}
if [ "$SSH_KEY_FILE" == "" ];then
	SSH_KEY_FILE=~/.ssh/id_rsa
fi
myscp="scp -i $SSH_KEY_FILE"   #这里不是alias，也不是函数，比函数简单，和alias一样好使；非交互式shell不支持alias
myssh="ssh -tt -i $SSH_KEY_FILE"

function upload() {
	local src_file=$1 dst_ip=$2 dst_file=$3
	local basename=$(basename $src_file)
	if [[ "$dst_ip" == "" ]];then
		$myscp $src_file root@$IP_BAOLEIJI:$dst_file && echo "done" || echo "upload fail"
		exit $?
	fi

	$myscp $src_file root@$IP_BAOLEIJI:/tmp/$basename
	if [ $? != 0 ]; then
		exit 1
	fi
	$myssh root@$IP_BAOLEIJI "scp /tmp/$basename  root@$dst_ip:$dst_file;rm -f /tmp/$basename" 2>/dev/null
	echo done
}
function download() {
	local src_ip=$1 src_file=$2 dst_file=$3
	local basename=$(basename $src_file)
	if [[ "$src_ip" == "" ]]; then
		$myscp root@$IP_BAOLEIJI:$src_file $dst_file  && echo "done" || echo "fail"
		exit $?
	fi
	$myssh root@$IP_BAOLEIJI "scp root@$src_ip:$src_file /tmp/$basename "
	if [ $? != 0 ]; then
		exit 1
	fi
	$myscp root@$IP_BAOLEIJI:/tmp/$basename $dst_file
	$myssh root@$IP_BAOLEIJI "rm /tmp/$basename " 2>/dev/null
	echo done
}
function main(){
	local method=$1
	if [ -z $method ] || [[ "$method" != "upload" && "$method" != "download" ]];then
		echo "Usage:"
		echo "	$0 method ..."
		exit 1
	fi
	shift
	if [ $method == "upload" ];then
		local src_file=$1 dst=$2
		if [ -z $src_file ] || [ -z $dst ]; then
			echo "Usage:"
			echo "	$0 upload src_file dst_ip:dst_file"
			exit 1
		fi
		echo $dst | (IFS=":"; read dst_ip dst_file;IFS="  "; upload "$src_file" "$dst_ip" "$dst_file")
	fi
	if [ $method == "download" ];then
		local src=$1 dst_file=$2
		if [ -z $dst_file ] || [ -z $src ]; then
			echo "Usage:"
			echo "	$0 download src_ip:src_file dst_file"
			exit 1
		fi
		echo $src| (IFS=":"; read src_ip src_file;IFS="  ";	download "$src_ip" "$src_file" "$dst_file" )
	fi
}
main "$@"
