#!/usr/bin/env bash

SCRIPT="`pwd`/getPackageInfo.py"

CLASSFILE="`pwd`/ROSGenMsg"

# on my machine, messages are located in:

echo "// This is an auto-generated file." >> "$CLASSFILE.h"
echo "#import \"ROSMsg.h\"" > "$CLASSFILE.h"

echo "// This is an auto-generated file." >> "$CLASSFILE.m"
echo "#import \"$CLASSFILE.h\"" > "$CLASSFILE.m"

pushd /opt/ros/groovy/
msgs=`find . -name \*\.msg`

a=""

for m in $msgs; do
    a="$a `$SCRIPT $m $CLASSFILE`"
    
    #echo $a
    #./genClass.py < $a
done

popd

echo $a | ./prettyPrintClasses.py
