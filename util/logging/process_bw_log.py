import csv
import sys

CLOCK_CYCLE_TIME=4
def calculate_bws(in_filename):
    with open(in_filename, "r") as csvfile:
        reader = csv.DictReader(csvfile)
        interval_bws = []

        entries = []
        for row in reader:
            entries.append(row)

        for i in range(1, len(entries)):
            bw_time_1 = int(entries[i]["timestamp"])
            bw_time_0 = int(entries[i-1]["timestamp"])
            time_period = bw_time_1 - bw_time_0
            time_period_ns = time_period * CLOCK_CYCLE_TIME
            time_period_s = time_period_ns/(10**9)

            bytes_sent = (int(entries[i]["bytes"]) -
                    int(entries[i-1]["bytes"]))
            bits_sent = bytes_sent * 8
            interval_bws.append(bits_sent/time_period_s)

    return interval_bws

def process_bws(in_filename, out_filename):
    bws = calculate_bws(in_filename)
    with open(out_filename, "w") as out_file:
        for bw in bws:
            out_file.write(f"{bw}\n")


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: process_bw_log.py <input_filename> <output_filename>")
        exit(1)

    process_bws(sys.argv[1], sys.argv[2])
