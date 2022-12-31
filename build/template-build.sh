# use tpage from template toolkit to build each shtml file

echo "# Template script" > script.sh
(find ../htdocs -name \*shtml \
  -exec echo -n "( cd " \;  \
  -exec dirname -z {} \; \
  -exec echo -n " && tpage " \;  \
  -exec basename -z {} \; \
  -exec echo -n " > tmp " \;  \
  -exec echo -n " && mv tmp " \;  \
  -exec basename -z {} \; \
  -exec echo ")" \; \
) >> script.sh
# Now we need to remove the nulls from -z
perl -i -pe 's/\000//g' script.sh

