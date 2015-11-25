#!/bin/sh

cwd=$(dirname $0)
cache_dir=$cwd/cache
gitinspector=/data2/gitinspector/gitinspector.py
htdocs=/data1/htdocs/cs.i.beebank.com
log_file=$cwd/cs.log
conf_dir=$cwd/conf

[ -d $cache_dir ] || mkdir -p $cache_dir
function mylog() {
	echo $(date +'%F %T') $* >>$log_file
}

conf_files=$conf_dir/*.conf
if [ ! -z $1 ]; then
	conf_files=$conf_dir/$1.conf
fi

for f in $conf_files
do
	. $f
        pname=$( basename ${f%.conf})
        pdir=$cache_dir/$pname

	mylog "------- begin $pname --------"
	if [ -d $pdir ]; then
		mylog update...
		(cd $pdir; git svn rebase >/dev/null)
		if [ $? != 0 ]; then
			mylog "update failed" && mylog "end" && continue
		fi
	else
		mylog clone...
		git svn clone --username $username -T trunk $url $pdir >/dev/null 2>&1
		if [ $? != 0 ]; then
			mylog "clone failed" && mylog "end" && continue
		fi
	fi

	version=$(cd $pdir; git svn info |awk '$1 == "Revision:"{print $2}')

	phtdocs=$htdocs/$pname
	phtml=$pname.html
	access_html=$htdocs/$phtml
	target_html=$phtdocs/$version.html
	index_html=$htdocs/index.html

	[ -f $index_html ] || touch $index_html
	if ! grep $pname $index_html >/dev/null 2>&1; then
		echo "<li><a href='${pname}.html'>${pname}</a></li>" >>$index_html
	fi

	if [ -f $target_html ] ;then
		mylog $pname skip
	else
		[ -d $phtdocs ] || mkdir -p $phtdocs

		mylog gitinspect
		$gitinspector -f '**' -F html $pdir >$target_html
	fi
	[ -f $access_html ] && unlink $access_html
	ln -s $target_html $access_html
	mylog end $pname
done
mylog "------ finish ------"
