#Turing MAchine Simulator - COre Engine
class TuringMachine:
    """
    Components: 
    - states: Set of states the machine can be in
    - alphabet: Set of symbols that can appear on the tape
    - blank_symbol: Symbol representing blank tape cells
    - transitions: Dictionary defining state transitions
    - initial_state: Starting state
    - accept_states: States that indicate acceptance
    - reject_states: States that indicate rejection
    """
    def __init__(self, states, alphabet, blank_symbol, transitions, initial_state, accept_states, reject_states):
        self.states = set(states)
        self.alphabet = set(alphabet)
        self.blank_symbol = blank_symbol
        self.transitions = transitions
        self.initial_state = initial_state
        self.accept_states = set(accept_states)
        self.reject_states = set(reject_states)

        self.tape = []
        self.head_position = 0
        self.current_state = initial_state
        self.trace = []
    
    def initialize_tape(self, input_string):
        """Initialize the tape with input string."""
        if input_string: 
            self.tape = list(input_string)
        else:
            self.tape = [self.blank_symbol]
        self.head_position = 0
        self.current_state = self.initial_state
        self.trace = []

        #Records initial configuration
        self._record_trace("INITIAL")

    def _record_trace(self, action = "STEP"):
        """Records current configuration for trace."""
        tape_str = ''.join(self.tape)

        #Creates visual representation with head position
        visual = list(tape_str)

        trace_entry = {
            'step': len(self.trace),
            'action': action,
            'state': self.current_state,
            'tape': tape_str,
            'head_position': self.head_position,
            'symbol_read': self.tape[self.head_position] if 0 <= self.head_position < len(self.tape) else self.blank_symbol
        }
        self.trace.append(trace_entry)

    def step(self):
        """Executes one step of the Turing Machine."""
        #Check if in accept/reject state
        if self.current_state in self.accept_states: 
            return "accept"
        if self.current_state in self.reject_states:
            return "reject"
        
        #Extend tape if needed
        if self.head_position < 0: 
            self.tape.insert(0, self.blank_symbol)
            self.head_position = 0
        elif self.head_position >= len(self.tape):
            self.tape.append(self.blank_symbol)

        #Read current symbol
        current_symbol = self.tape[self.head_position]

        #Look up transition
        transition_key = (self.current_state, current_symbol)

        if transition_key not in self.transitions:
            #No transition defined - reject
            self.current_state = list(self.reject_states)[0] if self.reject_states else "reject"
            self._record_trace("NO TRANSITION")
            return "reject"
        
        #Execute transition
        next_state, write_symbol, move_direction = self.transitions[transition_key]

        #Write symbol
        self.tape[self.head_position] = write_symbol

        #Move head
        if move_direction == 'L':
            self.head_position -= 1
        elif move_direction == 'R':
            self.head_position += 1
        #'S' ,means stay (no movement)

        #Update state
        self.current_state = next_state

        #Record this step
        self._record_trace("STEP")

        return 'continue'
    
    def run(self, input_string, max_steps = 1000): 
        """Runs the Turing Machine on input string."""
        self.initialize_tape(input_string)

        steps = 0
        while steps < max_steps: 
            result = self.step()
            steps += 1

            if result == 'accept': 
                self._record_trace("ACCEPT")
                return{
                    'accepted': True,
                    'trace': self.trace,
                    'final_tape': ''.join(self.tape),
                    'steps': steps,
                    'reason': 'Input accepted - reached accept state'
                }
            elif result == 'reject':
                self._record_trace("REJECT")
                return{
                    'accepted': False,
                    'trace': self.trace,
                    'final_tape': ''.join(self.tape),
                    'steps': steps,
                    'reason': 'Input rejected - reached reject state or no valid transition'  
                }
        #Max steps exceeded
        self._record_trace("TIMEOUT")
        return{
            'accepted': False,
            'trace': self.trace,
            'final_tape': ''.join(self.tape),
            'steps': steps,
            'reason': f'Exceeded maximum steps ({max_steps})'
        }

# =============================================================================
# TESTING CODE
# =============================================================================

if __name__ == "__main__":
    print("=" * 60)
    print("Testing Turing Machine Core")
    print("=" * 60)
    print()
    
    # Simple test: Accept strings of 1s
    print("Test 1: Simple TM that accepts strings of all 1s")
    print("-" * 60)
    
    tm = TuringMachine(
        states=['q0', 'q_accept', 'q_reject'],
        alphabet=['1', '_'],
        blank_symbol='_',
        transitions={
            ('q0', '1'): ('q0', '1', 'R'),      # Keep reading 1s
            ('q0', '_'): ('q_accept', '_', 'S'), # Reached end, accept
        },
        initial_state='q0',
        accept_states=['q_accept'],
        reject_states=['q_reject']
    )
    
    test_inputs = ['1', '11', '111', '1111']
    
    for test_input in test_inputs:
        result = tm.run(test_input)
        status = "✓ ACCEPT" if result['accepted'] else "✗ REJECT"
        print(f"{status} | Input: '{test_input}' | Steps: {result['steps']}")
    
    print()
    print("Test 2: Detailed trace for input '11'")
    print("-" * 60)
    
    result = tm.run('11')
    print(f"Result: {'ACCEPTED' if result['accepted'] else 'REJECTED'}")
    print(f"Steps taken: {result['steps']}")
    print()
    print("State Trace:")
    for entry in result['trace']:
        tape_visual = list(entry['tape'])
        if 0 <= entry['head_position'] < len(tape_visual):
            tape_visual[entry['head_position']] = f"[{tape_visual[entry['head_position']]}]"
        print(f"  Step {entry['step']:2d}: State={entry['state']:10s} Tape={''.join(tape_visual)}")
    
    print()
    print("=" * 60)
    print("✅ Core Turing Machine tests complete!")
    print("=" * 60)