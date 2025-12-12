"""
Turing Machine Simulator
A simple implementation that checks if binary strings have equal 0s and 1s
"""

class TuringMachine:
    def __init__(self):
        # Define the states for checking equal 0s and 1s
        self.states = {
            'start', 'find_zero', 'find_one', 'check_marked',
            'accept', 'reject'
        }
        self.initial_state = 'start'
        self.accept_state = 'accept'
        self.reject_state = 'reject'
        self.blank_symbol = '_'
        
        # Transition function: (current_state, read_symbol) -> (next_state, write_symbol, direction)
        # Direction: 'L' = left, 'R' = right
        self.transitions = {
            # Start: move to rightmost position
            ('start', '0'): ('start', '0', 'R'),
            ('start', '1'): ('start', '1', 'R'),
            ('start', 'X'): ('start', 'X', 'R'),
            ('start', '_'): ('find_zero', '_', 'L'),
            
            # Find an unmarked 0
            ('find_zero', '0'): ('find_one', 'X', 'L'),
            ('find_zero', '1'): ('find_zero', '1', 'L'),
            ('find_zero', 'X'): ('find_zero', 'X', 'L'),
            ('find_zero', '_'): ('check_marked', '_', 'R'),
            
            # Find an unmarked 1 to pair with the 0
            ('find_one', '1'): ('start', 'X', 'R'),
            ('find_one', '0'): ('find_one', '0', 'L'),
            ('find_one', 'X'): ('find_one', 'X', 'L'),
            ('find_one', '_'): ('reject', '_', 'R'),
            
            # Check if all symbols are marked
            ('check_marked', 'X'): ('check_marked', 'X', 'R'),
            ('check_marked', '_'): ('accept', '_', 'R'),
            ('check_marked', '0'): ('reject', '0', 'R'),
            ('check_marked', '1'): ('reject', '1', 'R'),
        }
        
    def run(self, input_string, max_steps=1000):
        """
        Run the Turing Machine on the input string
        Returns: (accepted, trace)
        """
        # Initialize tape with input
        tape = list(input_string) + [self.blank_symbol]
        head = 0
        state = self.initial_state
        steps = 0
        trace = []
        
        # Record initial configuration
        trace.append({
            'step': steps,
            'state': state,
            'tape': ''.join(tape),
            'head': head,
            'action': 'Initial configuration'
        })
        
        while state not in {self.accept_state, self.reject_state} and steps < max_steps:
            steps += 1
            
            # Read current symbol
            current_symbol = tape[head] if head < len(tape) else self.blank_symbol
            
            # Get transition
            key = (state, current_symbol)
            if key not in self.transitions:
                # No transition defined = reject
                state = self.reject_state
                trace.append({
                    'step': steps,
                    'state': state,
                    'tape': ''.join(tape),
                    'head': head,
                    'action': f'No transition for ({state}, {current_symbol}) - REJECT'
                })
                break
            
            next_state, write_symbol, direction = self.transitions[key]
            
            # Write symbol
            tape[head] = write_symbol
            
            # Record action
            action = f"Read '{current_symbol}', wrote '{write_symbol}', moved {direction}"
            trace.append({
                'step': steps,
                'state': next_state,
                'tape': ''.join(tape),
                'head': head,
                'action': action
            })
            
            # Move head
            if direction == 'R':
                head += 1
                if head >= len(tape):
                    tape.append(self.blank_symbol)
            elif direction == 'L':
                head -= 1
                if head < 0:
                    tape.insert(0, self.blank_symbol)
                    head = 0
            
            state = next_state
        
        accepted = (state == self.accept_state)
        return accepted, trace
    
    def print_trace(self, trace):
        """Print the execution trace in a readable format"""
        print("\n" + "="*80)
        print("TURING MACHINE EXECUTION TRACE")
        print("="*80)
        
        for entry in trace:
            print(f"\nStep {entry['step']}: State = {entry['state']}")
            print(f"  Tape: {entry['tape']}")
            print(f"  Head: {' '*entry['head']}^")
            print(f"  Action: {entry['action']}")
        
        print("\n" + "="*80)


def main():
    print("="*80)
    print("TURING MACHINE SIMULATOR")
    print("="*80)
    print("\nThis Turing Machine checks if a binary string has equal numbers of 0s and 1s")
    print("Examples: '01' -> PASS, '0011' -> PASS, '010' -> FAIL, '111' -> FAIL")
    print("\nAlgorithm:")
    print("  1. Mark pairs of 0s and 1s with 'X'")
    print("  2. If all symbols are marked and tape ends -> ACCEPT")
    print("  3. If unpaired symbols remain -> REJECT")
    print("="*80)
    
    tm = TuringMachine()
    
    # Get input from user
    print("\nEnter a binary string (or 'quit' to exit):")
    user_input = input("> ").strip()
    
    if user_input.lower() == 'quit':
        print("Goodbye!")
        return
    
    # Validate input
    if not all(c in '01' for c in user_input):
        print("ERROR: Input must contain only 0s and 1s")
        return
    
    if len(user_input) == 0:
        print("ERROR: Input cannot be empty")
        return
    
    print(f"\nProcessing input: '{user_input}'")
    
    # Run the Turing Machine
    accepted, trace = tm.run(user_input)
    
    # Print the trace
    tm.print_trace(trace)
    
    # Print result
    print("\nRESULT:")
    if accepted:
        print(f"✓ PASS - Input '{user_input}' is ACCEPTED")
        print(f"  The string has equal numbers of 0s and 1s")
    else:
        print(f"✗ FAIL - Input '{user_input}' is REJECTED")
        print(f"  The string does NOT have equal numbers of 0s and 1s")
    print("="*80)


if __name__ == "__main__":
    main()