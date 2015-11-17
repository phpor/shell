1. 检查文件修改时间距离现在多长时间
  echo $((`date "+%s"` - `stat -c '%Y' the_file`))
