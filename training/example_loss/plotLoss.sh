#!/bin/bash
# Usage parse_log.sh caffe.log
# It creates the following two text files, each containing a table:
#     caffe.log.test (columns: '#Iters Seconds TestAccuracy TestLoss')
#     caffe.log.train (columns: '#Iters Seconds TrainingLoss LearningRate')


# get the dirname of the script
# DIR="$( cd "$(dirname "$0")" ; pwd -P )"

if [ "$#" -lt 1 ]
then
echo "Usage parse_log.sh /path/to/your.log"
exit
fi
LOG=`basename $1`
DIR=`dirname $1`
 
# For extraction of time since this line contains the start time
grep '] Solving ' $1 > aux.txt
grep ', loss = ' $1 >> aux.txt
grep 'Iteration ' aux.txt | sed  's/.*Iteration \([[:digit:]]*\).*/\1/g' > aux0.txt
grep ', loss = ' $1 | awk '{print $9}' > aux1.txt
grep ', lr = ' $1 | awk '{print $9}' > aux2.txt
grep ': loss_stage3_L1 = ' $1 | awk '{print $11}' > aux3.txt
grep ': loss_stage3_L2 = ' $1 | awk '{print $11}' > aux4.txt

# Extracting elapsed seconds
# $DIR/extract_seconds.py aux.txt aux3.txt

# Generating
echo '#Iters Loss_toal LearningRate loss_L1 loss_L2'> $DIR/$LOG.train
paste aux0.txt aux1.txt aux2.txt aux3.txt aux4.txt | column -t >> $DIR/$LOG.train
rm aux.txt aux0.txt aux1.txt aux2.txt aux3.txt aux4.txt

#echo $DIR
#echo $LOG
gnuplot -e "filename='$DIR/$LOG.train';dirname='$DIR'" plot_log.gnuplot