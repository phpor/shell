#!/bin/bash

if [ "$SSH_KEY_FILE" == "" ];then
	SSH_KEY_FILE=~/.ssh/ali_baoleiji_id_rsa
fi
myscp="scp -i $SSH_KEY_FILE -P 13322"
myssh="ssh -tt -i $SSH_KEY_FILE -p 13322"

function upload() {
	local src_file=$1 dst_ip=$2 dst_file=$3
	if [[ "$dst_ip" == "" ]];then
		cat $src_file | ssh ali "cat >$dst_file"
		exit $?
	fi
	cat $src_file | ssh ali "ssh $dst_ip cat >$dst_file"
	echo done
}

function download() {
	local src_ip=$1 src_file=$2 dst_file=$3
	if [[ "$src_ip" == "" ]]; then
		ssh ali "cat $src_file" >$dst_file
		exit $?
	fi
	ssh ali "ssh $src_ip cat $src_file" >$dst_file
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
