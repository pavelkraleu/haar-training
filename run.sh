#!/bin/bash

samples_per_image=10

width=150
height=50

mem_limit=2000

nice_limit=20

nstages=20

minhit=0.99
maxfalse=0.3


function list_positives {
	find positives/ -type f  | sort -R > positives.txt
}

function list_negatives {
	find negatives/ -type f  | sort -R > negatives.txt
}

function gen_vector_name {
	randomnum=$[ ( $RANDOM % 10000 )  + 1 ]
	echo $randomnum".vec"
}

function gen_vectors {
	echo "Generating vectors"

	rm -r vectors/ 2> /dev/null
	mkdir vectors/
	rm vectors.vec 2> /dev/null
	rm vectors.txt 2> /dev/null
	
	for image in `cat positives.txt`; do
		# echo $image
		# for debug add -show on the end
		cmd="/usr/local/bin/opencv_createsamples -bgcolor 0 -bgthresh 0 -maxxangle 1.1 -maxyangle 1.1 maxzangle 0.5 -maxidev 40 -w $width -h $height -img $image -bg negatives.txt -num $samples_per_image -vec vectors/`gen_vector_name`"
		echo $cmd >> logs.txt
		eval $cmd >> logs.txt 2>&1
	done

	for vector in `ls vectors/*.vec`; do 
		size=`du $vector | awk '{print($1)}'`; 
		if [ $size -eq 0 ] ; then 
			echo "File $vector is empty. Deleting" >> logs.txt
			rm $vector; 
		fi; 
	done

	find vectors/ -name '*.vec' > vectors.txt
	cmd="./mergevec vectors.txt vectors.vec"
	echo $cmd >> logs.txt
	eval $cmd >> logs.txt 2>&1
}

function train {
	echo "Starting training"
	rm -r haar/ 2> /dev/null
	mkdir haar/
	
	numpos=`cat positives.txt | wc -l`
	let "numposcomp=$numpos * $samples_per_image / 2"

	cmd="nice -n $nice_limit /usr/local/bin/opencv_traincascade -data haar -vec vectors.vec -bg negatives.txt -w $width -h $height -numPos  $numposcomp -numNeg `cat negatives.txt | wc -l` -precalcValBufSize $mem_limit -precalcIdxBufSize $mem_limit  -baseFormatSave -maxFalseAlarmRate $maxfalse -minHitRate $minhit -numStages $nstages -mode ALL"
	#echo $cmd

	echo $cmd >> logs.txt
	eval "$cmd >> logs.txt 2>&1 &"
	pid=$!

	echo $pid > pid

	cmd="./watcher.sh `pwd`"
	echo $cmd >> logs.txt
	eval "$cmd >> logs.txt 2>&1 &"

	echo "All done"
}

echo > logs.txt

list_positives
list_negatives

gen_vectors

train



