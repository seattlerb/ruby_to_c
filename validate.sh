#!/bin/bash

# set -xv

trap "exit 1" 1 2 3 15

DIRS="-I../../metaruby/dev/tests/builtin:../../metaruby/dev/tests:../../ParseTree/dev/test:../../ParseTree/dev/lib"
for d in $(ls -d ../../*/dev | grep -v ruby_to_c); do
    DIRS="-I$d $DIRS"
done

if [ -z "$1" ]; then
    if [ -f rb.bad.txt ]; then
	mv rb.bad.txt rb.files.txt
    else
	find ../../*/dev /usr/local/lib/ruby/1.8/ -name \*.rb | grep -v tk | xargs egrep -l "^(class|module)" > rb.files.txt
    fi

    total_count=$(wc -l rb.files.txt | awk '{print $1}')
    curr_count=0
    good_count=0
    for f in $(cat rb.files.txt); do
	curr_count=$(($curr_count + 1))
	if GEM_SKIP=ParseTree ruby $DIRS ./translate.rb $f &> /tmp/r2c.$$ < /dev/null; then
	    echo $f >> rb.good.txt
	    status=pass
	    good_count=$(($good_count + 1))
	else
	    echo $f >> rb.bad.txt	
	    cat /tmp/r2c.$$ >> rb.err.txt
	    status=fail
	fi
	fname=`basename $f`
	pct=$(echo "$good_count / $curr_count * 100.0" | bc -l)
	printf "%4d/%4d (%6.2f%%): %s %s\n" $curr_count $total_count $pct $status $fname
    done
else
    if [ "$1" == "-q" ]; then
	GEM_SKIP=ParseTree ruby $DIRS ./translate.rb "$2" 2>&1 | egrep "(ERROR|no:)" | perl -pe '
s/ in .*//;
s/(translating \S+):/$1/;
s/(is not an Array \w+):.*/$1/;
s/.* (is not a supported node type)/blah $1/;
s/(Unable to unify).*/$1/;
s/(Unknown literal) \S+/$1/;' | occur 
    else
	GEM_SKIP=ParseTree ruby $DIRS ./translate.rb "$1"
    fi
fi