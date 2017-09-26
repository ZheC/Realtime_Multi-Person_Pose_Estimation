# These snippets serve only as basic examples.
# Customization is a must.
# You can copy, paste, edit them in whatever way you want.
# Be warned that the fields in the training log may change in the future.
# You had better check the data files before designing your own plots.

# Please generate the neccessary data files with 
# /path/to/caffe/tools/extra/parse_log.sh before plotting.
# Example usage: 
#     ./parse_log.sh mnist.log
# Now you have mnist.log.train and mnist.log.test.
#     gnuplot mnist.gnuplot

# The fields present in the data files that are usually proper to plot along
# the y axis are test accuracy, test loss, training loss, and learning rate.
# Those should plot along the x axis are training iterations and seconds.
# Possible combinations:
# 1. Test accuracy (test score 0) vs. training iterations / time;
# 2. Test loss (test score 1) time;
# 3. Training loss vs. training iterations / time;
# 4. Learning rate vs. training iterations / time;
# A rarer one: Training time vs. iterations.

reset
set terminal png
set output dirname."/Loss_l1.png"
set style data lines
set key right

###### Fields in the data file your_log_name.log.train are
###### Iters Seconds TrainingLoss LearningRate

# Training loss vs. training iterations
set title "Training loss vs. training iterations"
set xlabel "Training iterations"
set ylabel "Training loss"
set yrange [0:700]
plot filename every 20 using 1:4 title "L1 2e-5"


reset
set terminal png
set output dirname."/Loss_l2.png"
set style data lines
set key right

# Training loss vs. training iterations
set title "Training loss vs. training iterations"
set xlabel "Training iterations"
set ylabel "Training loss"
set yrange [0:70]

plot filename every 20 using 1:5 title "L2 2e-5"

#plot "output.txt.train" every 10 using 1:4 title "L1 5e-6", \
#	 "output.txt.train" every 10 using 1:5 title "L2 5e-6", \


# Learning rate vs. training iterations;
# plot "mnist.log.train" using 1:4 title "mnist"