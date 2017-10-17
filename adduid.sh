#!/bin/bash
function usage(){
	cat <<eof
Usage:
	$0 uid uidNumber mobile
eof
	exit
}
if [[ $# -ne 3 ]];then
	usage
fi
uid=$1
gid=$uid
uidNumber=$2
gidNumber=$uidNumber
mobile=$3

content=$(cat <<eof
dn: uid=$uid,ou=People,dc=auth,dc=beebank,dc=com
changetype: modify
add: objectClass
objectClass: person
-
add: objectClass
objectClass: organizationalPerson
-
add: objectClass
objectClass: posixAccount
-
add: objectClass
objectClass: top
-
add: homeDirectory
homeDirectory: /home/$uid
-
add: gidNumber
gidNumber: $gidNumber
-
add: uidNumber
uidNumber: $uidNumber
-
add: description
description: $uid
-
add: mobile
mobile: $mobile

eof
)

echo "$content"
echo -n "Are you sure?(y/n):"
read ok
[ $ok != "y" ] && echo "canceled" && exit
echo "$content" | ldapmodify -D "cn=admin,dc=beebank,dc=com" -w xxxxx
