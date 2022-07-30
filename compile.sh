#! /bin/bash
. $(dirname $0)/env.sh
mkdir -p classes
javac -d classes -cp $CLASSPATH $(find . -name *.java)
