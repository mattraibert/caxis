import tensorflow as tf
import sys
import csv

image_paths = sys.argv[1:]
label_lines = [line.rstrip() for line in tf.gfile.GFile("/tf_files/out/retrained_labels.txt")]

with open('/tf_files/out/labels.csv', 'w') as csv_file:
    result_writer = csv.writer(csv_file)
    result_writer.writerow(["test file"] + label_lines)

    # Unpersists graph from file
    with tf.gfile.FastGFile("/tf_files/out/retrained_graph.pb", 'rb') as f:
        graph_def = tf.GraphDef()
        graph_def.ParseFromString(f.read())
        _ = tf.import_graph_def(graph_def, name='')

    with tf.Session() as sess:
        # Feed the image_data as input to the graph and get first prediction
        softmax_tensor = sess.graph.get_tensor_by_name('final_result:0')

        for image_path in image_paths:
            # Read in the image_data
            image_data = tf.gfile.FastGFile(image_path, 'rb').read()

            predictions = sess.run(softmax_tensor, {'DecodeJpeg/contents:0': image_data})
            top_k = predictions[0].argsort()[-len(predictions[0]):][::-1]

            scores = map(lambda x: '%.2f' % x, predictions[0])
            result_writer.writerow([image_path] + scores)
            # Sort to show labels of first prediction in order of confidence
            #
            # for node_id in top_k:
            #     print(node_id)
            #     human_string = label_lines[node_id]
            #     score = predictions[0][node_id]
            #     print('%s (score = %.5f)' % (human_string, score))
