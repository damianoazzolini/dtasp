import argparse
import clingo
import time

parser = argparse.ArgumentParser()
parser.add_argument('-d', type=str, required=True, help='Dataset to use')
parser.add_argument('-min-s', type=int, help='Min size (# all nodes) of the decision tree')
parser.add_argument('-max-s', type=int, required=True, help='Max size (# all nodes) of the decision tree')
args = parser.parse_args()

if args.min_s % 2 == 0:
    print("Min size must be odd, decrementing by 1")
    args.min_s -= 1
if args.max_s % 2 == 0:
    print("Max size must be odd, incrementing by 1")
    args.max_s += 1

for sz in range(args.min_s, args.max_s + 1, 2):
    start_time = time.time()
    print(f"Trying size {sz}")
    ctl = clingo.Control()
    ctl.load("encoding_improved_v2.lp")
    ctl.add("base", [], f"size({sz}).")
    fp = open(args.d, "r")
    for line in fp:
        ctl.add("base", [], line.strip())
    fp.close()
    ctl.ground([("base", [])])

    # solve until I get an answer set, if I get one, print it and break the loop
    solved = False
    with ctl.solve(yield_=True) as handle:
        for m in handle:
            print("Answer Set:")
            print(m)
            solved = True
            break
    end_time = time.time()
    print(f"Total time: {end_time - start_time:.2f} seconds")

    if solved:
        break

if not solved:
    print("No solution found for any size up to the max size.")
else:
    print(f"*** Solution found for size {sz} ***")