import json
import sys
import argparse

MAX_STEPS = 200000  # Prevent infinite loops

class TuringMachine:
    def __init__(self, tm_definition):
        self.states = tm_definition["states"]
        self.input_alphabet = tm_definition["input_alphabet"]
        self.tape_alphabet = tm_definition["tape_alphabet"]
        self.blank = tm_definition["blank"]
        self.start_state = tm_definition["start_state"]
        self.accept_state = tm_definition["accept_state"]
        self.reject_state = tm_definition["reject_state"]
        self.transitions = tm_definition["transitions"]

    def run(self, tape_str):
        tape = list(tape_str) + [self.blank]
        head = 0
        state = self.start_state
        step = 0

        print("=== Turing Machine Execution Trace ===")

        while True:
            # Prevent infinite execution
            if step > MAX_STEPS:
                print("\nERROR: Step limit exceeded → FAIL\n")
                return False

            # Print current state of tape
            readable_tape = "".join(tape)
            print(f"Step {step}: State={state}, Head={head}, Tape={readable_tape}")

            if state == self.accept_state:
                print("\nRESULT: PASS (Accepted)")
                return True

            if state == self.reject_state:
                print("\nRESULT: FAIL (Rejected)")
                return False

            symbol = tape[head]
            key = f"{state},{symbol}"

            if key not in self.transitions:
                print(f"\nNo transition defined for ({state}, {symbol}) → FAIL")
                return False

            new_symbol, direction, new_state = self.transitions[key]

            tape[head] = new_symbol

            # Move head
            if direction == "R":
                head += 1
                if head == len(tape):
                    tape.append(self.blank)
            elif direction == "L":
                head = max(0, head - 1)

            # Update state
            state = new_state
            step += 1


def load_tm(path):
    with open(path, "r") as f:
        return json.load(f)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Turing Machine Simulator")
    parser.add_argument("input_string", help="Input string for the Turing Machine")
    parser.add_argument("--tm", default="tm_definition.json", help="Path to TM definition JSON file")

    args = parser.parse_args()

    tm_def = load_tm(args.tm)
    tm = TuringMachine(tm_def)
    tm.run(args.input_string)
