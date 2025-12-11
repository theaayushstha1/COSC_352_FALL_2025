import json
import sys

class TuringMachine:
    def __init__(self, config):
        self.states = config["states"]
        self.start = config["start"]
        self.accept = config["accept"]
        self.reject = config["reject"]
        self.blank = "_"
        self.transitions = config["transitions"]

    def run(self, tape):
        tape = list(tape) + [self.blank]
        head = 0
        state = self.start
        trace = []

        while True:
            symbol = tape[head] if head < len(tape) else self.blank
            trace.append(f"State={state}, Head={head}, Read={symbol}, Tape={''.join(tape)}")

            if state == self.accept:
                return True, trace
            if state == self.reject:
                return False, trace

            key = f"{state},{symbol}"
            if key not in self.transitions:
                return False, trace

            new_state, write, move = self.transitions[key]
            tape[head] = write

            if move == ">":
                head += 1
            elif move == "<":
                head -= 1
                if head < 0:
                    tape.insert(0, self.blank)
                    head = 0

            state = new_state

def load_config():
    with open("tm_config.json") as f:
        return json.load(f)

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python main.py <input_string>")
        sys.exit(1)

    tape_input = sys.argv[1]
    config = load_config()
    tm = TuringMachine(config)
    result, trace = tm.run(tape_input)

    print("\n--- STATE TRACE ---")
    for step in trace:
        print(step)

    print("\nRESULT:", "ACCEPT" if result else "REJECT")
