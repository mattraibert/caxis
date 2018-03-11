#!/bin/bash

python /tensorflow/tensorflow/examples/image_retraining/retrain.py \
 --bottleneck_dir=/tf_files/bottlenecks \
 --how_many_training_steps 2048 \
 --model_dir=/tf_files/inception \
 --output_graph=/tf_files/out/retrained_graph.pb \
 --output_labels=/tf_files/out/retrained_labels.txt \
 --image_dir /tf_files/data
