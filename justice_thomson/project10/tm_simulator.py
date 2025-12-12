import argparse
from collections import deque

class TuringMachine:
    def __init__(self, input_string, blank=' '):
        self.tape = list(input_string)  # Initial tape from input
        self.head = 0  # Start at position 0 (first symbol)
        self.state = 'q0'  # Initial state
        self.blank = blank
        self.accept_state = 'q5'
        self.reject_state = 'q_reject'
        self.max_steps = 10000  # Prevent infinite loops
        self.steps = 0

        # Transition table as dict: (state, symbol) -> (new_state, write, move)
        self.transitions = {
            ('q0', 'a'): ('q2', 'X', 'R'),
            ('q1', 'a'): ('q2', 'X', 'R'),
            ('q1', 'X'): ('q1', 'X', 'R'),  # Skip marked X's in q1
            ('q1', 'Y'): ('q1', 'Y', 'R'),
            ('q1', 'Z'): ('q1', 'Z', 'R'),
            ('q1', ' '): ('q5', ' ', 'N'),  # Blank to accept
            ('q2', 'a'): ('q2', 'a', 'R'),
            ('q2', 'b'): ('q3', 'Y', 'R'),
            ('q2', 'Y'): ('q2', 'Y', 'R'),
            ('q2', 'Z'): ('q2', 'Z', 'R'),
            ('q3', 'b'): ('q3', 'b', 'R'),
            ('q3', 'c'): ('q4', 'Z', 'L'),
            ('q3', 'Z'): ('q3', 'Z', 'R'),
            ('q4', 'a'): ('q4', 'a', 'L'),
            ('q4', 'b'): ('q4', 'b', 'L'),
            ('q4', 'X'): ('q1', 'X', 'R'),
            ('q4', 'Y'): ('q4', 'Y', 'L'),
            ('q4', 'Z'): ('q4', 'Z', 'L'),
        }

    def step(self):
        if self.head < 0:
            self.tape.insert(0, self.blank)
            self.head = 0
        elif self.head >= len(self.tape):
            self.tape.append(self.blank)

        symbol = self.tape[self.head]

        key = (self.state, symbol)
        if key in self.transitions:
            new_state, write, move = self.transitions[key]
            self.tape[self.head] = write
            if move == 'R':
                self.head += 1
            elif move == 'L':
                self.head -= 1
            elif move == 'N':
                pass
            self.state = new_state
            return True
        else:
            self.state = self.reject_state
            return False

    def run(self, trace=True):
        while self.state not in [self.accept_state, self.reject_state] and self.steps < self.max_steps:
            if trace:
                self.print_trace()
            self.step()
            self.steps += 1

        if trace:
            self.print_trace()  # Final state

        if self.steps >= self.max_steps:
            return False, "Failed (exceeded max steps - possible loop)"
        elif self.state == self.accept_state:
            return True, "Passed (reached accept state q5)"
        else:
            return False, f"Failed (reached reject state: {self.state})"

    def print_trace(self):
        tape_str = ''.join(self.tape).rstrip(self.blank).lstrip(self.blank) or self.blank
        head_indicator = ' ' * (self.head - (len(self.tape) - len(tape_str.rstrip(self.blank))) ) + '^'
        print(f"State: {self.state}")
        print(f"Tape: {tape_str}")
        print(f"Head: {head_indicator}")
        print("-" * 40)

def main():
    parser = argparse.ArgumentParser(description="Turing Machine Simulator for a^n b^n c^n")
    parser.add_argument("input", type=str, help="Input string (e.g., aaabbbccc)")
    args = parser.parse_args()

    tm = TuringMachine(args.input)
    accepted, reason = tm.run(trace=True)
    print(f"Evaluation: {reason}")

if __name__ == "__main__":
    main()