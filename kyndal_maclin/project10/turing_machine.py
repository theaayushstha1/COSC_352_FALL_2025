"""
Turing Machine Simulator
A configurable Turing Machine implementation with state tracing
"""

class TuringMachine:
    def __init__(self, states, alphabet, tape_alphabet, transitions, initial_state, accept_state, reject_state, blank_symbol='_'):
        """
        Initialize a Turing Machine
        
        Args:
            states: Set of states
            alphabet: Input alphabet
            tape_alphabet: Tape alphabet (includes blank symbol)
            transitions: Dictionary of transitions {(state, symbol): (new_state, write_symbol, direction)}
            initial_state: Starting state
            accept_state: Accepting state
            reject_state: Rejecting state
            blank_symbol: Symbol representing blank on tape
        """
        self.states = states
        self.alphabet = alphabet
        self.tape_alphabet = tape_alphabet
        self.transitions = transitions
        self.initial_state = initial_state
        self.accept_state = accept_state
        self.reject_state = reject_state
        self.blank_symbol = blank_symbol
        
        self.tape = []
        self.head_position = 0
        self.current_state = initial_state
        self.state_trace = []
        self.step_count = 0
        self.max_steps = 10000  # Prevent infinite loops
        
    def load_tape(self, input_string):
        """Load input string onto the tape"""
        self.tape = list(input_string) if input_string else [self.blank_symbol]
        self.head_position = 0
        self.current_state = self.initial_state
        self.state_trace = []
        self.step_count = 0
        
    def get_tape_content(self):
        """Get current tape content as string"""
        return ''.join(self.tape)
    
    def step(self):
        """Execute one step of the Turing Machine"""
        if self.current_state in [self.accept_state, self.reject_state]:
            return False  # Machine has halted
        
        # Read current symbol
        current_symbol = self.tape[self.head_position]
        
        # Record state before transition
        self.state_trace.append({
            'step': self.step_count,
            'state': self.current_state,
            'head_position': self.head_position,
            'tape': self.get_tape_content(),
            'symbol_read': current_symbol
        })
        
        # Look up transition
        transition_key = (self.current_state, current_symbol)
        if transition_key not in self.transitions:
            # No transition defined, go to reject state
            self.current_state = self.reject_state
            return False
        
        new_state, write_symbol, direction = self.transitions[transition_key]
        
        # Execute transition
        self.tape[self.head_position] = write_symbol
        self.current_state = new_state
        
        # Move head
        if direction == 'R':
            self.head_position += 1
            if self.head_position >= len(self.tape):
                self.tape.append(self.blank_symbol)
        elif direction == 'L':
            self.head_position -= 1
            if self.head_position < 0:
                self.tape.insert(0, self.blank_symbol)
                self.head_position = 0
        
        self.step_count += 1
        return True
    
    def run(self, input_string):
        """
        Run the Turing Machine on input string
        
        Returns:
            tuple: (accepted: bool, trace: list, reason: str)
        """
        self.load_tape(input_string)
        
        while self.step_count < self.max_steps:
            if not self.step():
                break
        
        # Record final state
        self.state_trace.append({
            'step': self.step_count,
            'state': self.current_state,
            'head_position': self.head_position,
            'tape': self.get_tape_content(),
            'symbol_read': 'HALTED'
        })
        
        if self.current_state == self.accept_state:
            return True, self.state_trace, "Input accepted"
        elif self.current_state == self.reject_state:
            return False, self.state_trace, "Input rejected - no valid transition or explicit reject"
        else:
            return False, self.state_trace, f"Input rejected - exceeded maximum steps ({self.max_steps})"


def create_binary_palindrome_tm():
    """
    Create a Turing Machine that accepts binary palindromes
    Complexity: Medium
    """
    states = {'q0', 'q1', 'q2', 'q3', 'q4', 'accept', 'reject'}
    alphabet = {'0', '1'}
    tape_alphabet = {'0', '1', '_', 'X'}
    
    transitions = {
        # Mark leftmost 0, look for rightmost 0
        ('q0', '0'): ('q1', 'X', 'R'),
        # Mark leftmost 1, look for rightmost 1
        ('q0', '1'): ('q2', 'X', 'R'),
        # Empty string or single character is palindrome
        ('q0', '_'): ('accept', '_', 'R'),
        ('q0', 'X'): ('accept', 'X', 'R'),
        
        # Looking for rightmost 0
        ('q1', '0'): ('q1', '0', 'R'),
        ('q1', '1'): ('q1', '1', 'R'),
        ('q1', 'X'): ('q1', 'X', 'R'),
        ('q1', '_'): ('q3', '_', 'L'),
        
        # Looking for rightmost 1
        ('q2', '0'): ('q2', '0', 'R'),
        ('q2', '1'): ('q2', '1', 'R'),
        ('q2', 'X'): ('q2', 'X', 'R'),
        ('q2', '_'): ('q4', '_', 'L'),
        
        # Check if rightmost is 0
        ('q3', '0'): ('q0', 'X', 'L'),
        ('q3', 'X'): ('q3', 'X', 'L'),
        
        # Check if rightmost is 1
        ('q4', '1'): ('q0', 'X', 'L'),
        ('q4', 'X'): ('q4', 'X', 'L'),
        
        # Move back to start
        ('q0', '0'): ('q0', '0', 'L'),
        ('q0', '1'): ('q0', '1', 'L'),
    }
    
    return TuringMachine(states, alphabet, tape_alphabet, transitions, 'q0', 'accept', 'reject', '_')


def create_balanced_parentheses_tm():
    """
    Create a Turing Machine that accepts balanced parentheses
    Complexity: Hard
    """
    states = {'q0', 'q1', 'q2', 'q3', 'accept', 'reject'}
    alphabet = {'(', ')'}
    tape_alphabet = {'(', ')', '_', 'X'}
    
    transitions = {
        # Start: look for opening parenthesis
        ('q0', '('): ('q1', 'X', 'R'),
        ('q0', '_'): ('accept', '_', 'R'),
        ('q0', 'X'): ('q0', 'X', 'R'),
        
        # Find matching closing parenthesis
        ('q1', '('): ('q1', '(', 'R'),
        ('q1', ')'): ('q2', 'X', 'L'),
        ('q1', 'X'): ('q1', 'X', 'R'),
        
        # Go back to start
        ('q2', '('): ('q2', '(', 'L'),
        ('q2', 'X'): ('q2', 'X', 'L'),
        ('q2', '_'): ('q0', '_', 'R'),
    }
    
    return TuringMachine(states, alphabet, tape_alphabet, transitions, 'q0', 'accept', 'reject', '_')


def create_simple_tm():
    """
    Create a simple Turing Machine that accepts strings with equal 0s and 1s
    Complexity: Easy
    """
    states = {'q0', 'q1', 'q2', 'q3', 'accept', 'reject'}
    alphabet = {'0', '1'}
    tape_alphabet = {'0', '1', '_', 'X'}
    
    transitions = {
        # Mark a 0 and look for a 1
        ('q0', '0'): ('q1', 'X', 'R'),
        # Mark a 1 and look for a 0
        ('q0', '1'): ('q2', 'X', 'R'),
        # All marked, accept
        ('q0', 'X'): ('q0', 'X', 'R'),
        ('q0', '_'): ('accept', '_', 'R'),
        
        # Looking for 1 to mark
        ('q1', '0'): ('q1', '0', 'R'),
        ('q1', '1'): ('q3', 'X', 'L'),
        ('q1', 'X'): ('q1', 'X', 'R'),
        
        # Looking for 0 to mark
        ('q2', '1'): ('q2', '1', 'R'),
        ('q2', '0'): ('q3', 'X', 'L'),
        ('q2', 'X'): ('q2', 'X', 'R'),
        
        # Go back to start
        ('q3', '0'): ('q3', '0', 'L'),
        ('q3', '1'): ('q3', '1', 'L'),
        ('q3', 'X'): ('q3', 'X', 'L'),
        ('q3', '_'): ('q0', '_', 'R'),
    }
    
    return TuringMachine(states, alphabet, tape_alphabet, transitions, 'q0', 'accept', 'reject', '_')


def print_trace(trace):
    """Print the state trace in a formatted way"""
    print("\n" + "="*80)
    print("TURING MACHINE STATE TRACE")
    print("="*80)
    
    for entry in trace:
        print(f"\nStep {entry['step']}:")
        print(f"  State: {entry['state']}")
        print(f"  Head Position: {entry['head_position']}")
        print(f"  Tape: {entry['tape']}")
        print(f"  Symbol Read: {entry['symbol_read']}")
        
        # Visual representation
        if entry['symbol_read'] != 'HALTED':
            tape_visual = list(entry['tape'])
            pointer = ' ' * entry['head_position'] + '^'
            print(f"  Visual: {entry['tape']}")
            print(f"          {pointer}")
    
    print("\n" + "="*80)


if __name__ == "__main__":
    # Example usage
    print("Turing Machine Simulator - Testing Binary Palindrome")
    print("="*80)
    
    tm = create_binary_palindrome_tm()
    
    test_cases = [
        ("101", True),
        ("1001", True),
        ("110", False),
        ("0", True),
        ("11", True),
        ("010", True),
    ]
    
    for input_str, expected in test_cases:
        accepted, trace, reason = tm.run(input_str)
        status = "✓ PASS" if accepted == expected else "✗ FAIL"
        print(f"\nInput: '{input_str}' | Expected: {expected} | Got: {accepted} | {status}")
        print(f"Reason: {reason}")
        print(f"Steps: {len(trace) - 1}")