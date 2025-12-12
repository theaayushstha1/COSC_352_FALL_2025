class TuringMachine:
    """
    Core Turing Machine implementation
    
    A Turing Machine is defined by:
    - Q: Finite set of states
    - Σ: Input alphabet
    - Γ: Tape alphabet (Σ ⊆ Γ)
    - δ: Transition function Q × Γ → Q × Γ × {L, R, N}
    - q0: Start state
    - qaccept: Accept state
    - qreject: Reject state
    """
    
    def __init__(self, transitions, start_state, accept_state, reject_state):
        self.transitions = transitions
        self.start_state = start_state
        self.accept_state = accept_state
        self.reject_state = reject_state
        
    def run(self, input_string, max_steps=1000):
        """
        Execute the Turing Machine on input
        
        Returns:
            dict: {
                'accepted': bool,
                'trace': list of execution steps,
                'final_state': str
            }
        """
        # Initialize tape with blank symbols on both ends
        tape = ['B'] + list(input_string) + ['B', 'B', 'B', 'B']
        head = 1
        state = self.start_state
        trace = []
        steps = 0
        
        # Execute until acceptance, rejection, or max steps
        while state not in [self.accept_state, self.reject_state] and steps < max_steps:
            # Get current symbol under head
            symbol = tape[head] if head < len(tape) else 'B'
            
            # Record current configuration
            trace.append({
                'step': steps,
                'state': state,
                'tape': ''.join(tape).rstrip('B') + 'B',
                'head': head,
                'symbol': symbol
            })
            
            # Check if transition exists
            if state not in self.transitions or symbol not in self.transitions[state]:
                state = self.reject_state
                break
            
            # Get transition
            next_state, write_symbol, direction = self.transitions[state][symbol]
            
            # Write symbol
            tape[head] = write_symbol
            
            # Move head
            if direction == 'R':
                head += 1
            elif direction == 'L':
                head -= 1
            
            # Extend tape if necessary
            if head < 0:
                tape.insert(0, 'B')
                head = 0
            while head >= len(tape):
                tape.append('B')
            
            # Transition to next state
            state = next_state
            steps += 1
        
        # Record final configuration
        final_tape = ''.join(tape).rstrip('B') + 'B'
        trace.append({
            'step': steps,
            'state': state,
            'tape': final_tape,
            'head': head,
            'symbol': tape[head] if head < len(tape) else 'B',
            'final': True
        })
        
        return {
            'accepted': state == self.accept_state,
            'trace': trace,
            'final_state': state,
            'steps': steps
        }