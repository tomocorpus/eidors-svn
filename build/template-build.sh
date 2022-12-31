# use tpage from template toolkit to build each shtml file

find ../htdocs -name \*shtml -exec sh -c 'echo {} ; tpage {} > {}' \;

