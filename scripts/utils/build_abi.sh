#!/bin/bash

for dire in `ls contracts`; do
	if [ -f contracts/$dire ]; then
		continue;
	fi

	echo "build contracts/$dire/*.sol"

	solcjs --abi --optimize --optimize-runs 200 --include-path node_modules/ --base-path . contracts/$dire/*.sol -o ./abi/
	solcjs --bin --optimize --optimize-runs 200 --include-path node_modules/ --base-path . contracts/$dire/*.sol -o ./abi/
done

nowDir=`pwd`
cd ./abi

for name in `ls *.bin`; do
	mv $name ${name##*_}
done

for name in `ls *.abi`; do
	mv $name ${name##*_}
done

cd $nowDir

