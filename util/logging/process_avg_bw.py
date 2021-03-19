import csv
import sys
import argparse

def process_bws(in_filename, out_filename, drop_reads):
    total_num_reads = 0
    measures = []
    start = -1
    end = -1
    with open(in_filename, "r") as bws:
        for line in bws:
            # if the line is non-0 and start is unset, record the start
            if float(line) != 0.0:
                if start == -1:
                    start = total_num_reads
                measures.append(float(line))
            # otherwise, the line is 0. If we've already set start, this
            # is the end, so record it and break
            else:
                if start != -1:
                    end = total_num_reads
                    break
            total_num_reads += 1

    total = 0
    num_non_dropped = 0
    for measure in measures[drop_reads:len(measures)-drop_reads]:
        total += measure
        num_non_dropped += 1

    num_non_dropped = len(measures) - (2 * drop_reads)
    avg = total/num_non_dropped

    with open(out_filename, "w") as avg_file:
        avg_file.write(str(avg))

def setup_argparse():
    parser = argparse.ArgumentParser()
    parser.add_argument("--input_file", required=True, help="input data file")
    parser.add_argument("--output_file", required=True, help="output data file")
    parser.add_argument("--drop_reads", required=True, help="number of data points to consider warm up and cool down", type=int)

    return parser

if __name__ == "__main__":
    parser = setup_argparse()
    args = parser.parse_args()

    process_bws(args.input_file, args.output_file, args.drop_reads)
