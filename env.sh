#! /bin/bash

CLASSPATH=''

EXTERNAL_LIB_DIR="$(dirname $0)/external/lib"
for file in $(ls $EXTERNAL_LIB_DIR); do
  # echo $file
  CLASSPATH+="$EXTERNAL_LIB_DIR/$file:"
done

CLASSPATH+="$(dirname $0)/classes"
