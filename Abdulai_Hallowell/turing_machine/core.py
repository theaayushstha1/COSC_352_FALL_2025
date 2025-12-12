from typing import Dict, Tuple, List, Optional

Move = str  # 'L', 'R', or 'N'


class Tape:
    def __init__(self, input_str: str = "", blank: str = "_"):
        self.blank = blank
        # use list for tape and allow growth on both ends by adjusting head index
        self._tape = list(input_str) if input_str else [blank]
        self.head = 0

    def read(self) -> str:
        if self.head < 0 or self.head >= len(self._tape):
            return self.blank
        return self._tape[self.head]

    def write(self, symbol: str):
        if self.head < 0:
            # extend on left
            add = [-i for i in range(self.head, 0)]
            # simpler: prepend blanks
            self._tape = [self.blank] * (-self.head) + self._tape
            self.head += -self.head
        if self.head >= len(self._tape):
            self._tape.extend([self.blank] * (self.head - len(self._tape) + 1))
        self._tape[self.head] = symbol

    def move(self, direction: Move):
        if direction == 'L':
            self.head -= 1
        elif direction == 'R':
            self.head += 1
        elif direction == 'N':
            pass
        else:
            raise ValueError(f"Invalid move: {direction}")

    def get_tape_str(self, window: int = 20) -> str:
        # produce a readable tape with blank trimmed but show head with brackets
        tape = self._tape.copy()
        # ensure head inside tape
        if self.head < 0:
            tape = [self.blank] * (-self.head) + tape
            h = 0
        else:
            h = self.head

        # trim leading/trailing blanks for readability
        left = 0
        right = len(tape)
        while left < len(tape) and tape[left] == self.blank:
            left += 1
        while right > 0 and tape[right-1] == self.blank:
            right -= 1
        if left >= right:
            # all blanks
            tape_view = [self.blank]
            h = 0
        else:
            tape_view = tape[left:right]
            h = h - left

        # bound window
        if len(tape_view) > window:
            tape_view = tape_view[:window//2] + ['...'] + tape_view[-window//2:]
            if h >= window//2:
                # head in right half; adjust indicator approx
                pass

        # build string with head indicated
        out = ''
        for i, s in enumerate(tape_view):
            if i == h:
                out += '[' + s + ']'
            else:
                out += ' ' + s + ' '
        return out.strip()


class TuringMachine:
    def __init__(
        self,
        states: List[str],
        input_symbols: List[str],
        tape_symbols: List[str],
        blank_symbol: str,
        transitions: Dict[Tuple[str, str], Tuple[str, str, Move]],
        start_state: str,
        accept_states: List[str],
        reject_states: List[str],
    ):
        self.states = states
        self.input_symbols = set(input_symbols)
        self.tape_symbols = set(tape_symbols)
        self.blank_symbol = blank_symbol
        self.transitions = transitions
        self.start_state = start_state
        self.accept_states = set(accept_states)
        self.reject_states = set(reject_states)

    def validate_input(self, input_str: str) -> Optional[str]:
        for ch in input_str:
            if ch not in self.input_symbols:
                return ch
        return None

    def run(self, input_str: str, max_steps: int = 10000) -> Dict:
        invalid = self.validate_input(input_str)
        if invalid is not None:
            return {
                "error": True,
                "message": f"Input contains invalid symbol '{invalid}'. Valid symbols: {sorted(list(self.input_symbols))}",
            }

        tape = Tape(input_str, blank=self.blank_symbol)
        state = self.start_state
        steps = 0
        trace = []

        while steps < max_steps:
            cur_symbol = tape.read()
            trace.append(
                {
                    "step": steps,
                    "state": state,
                    "head": tape.head,
                    "tape": tape.get_tape_str(),
                    "read": cur_symbol,
                }
            )

            if state in self.accept_states:
                return {
                    "error": False,
                    "result": True,
                    "reason": f"Halted in accepting state {state} after {steps} steps.",
                    "steps": steps,
                    "trace": trace,
                }
            if state in self.reject_states:
                return {
                    "error": False,
                    "result": False,
                    "reason": f"Halted in rejecting state {state} after {steps} steps.",
                    "steps": steps,
                    "trace": trace,
                }

            key = (state, cur_symbol)
            if key not in self.transitions:
                # no valid transition -> reject
                return {
                    "error": False,
                    "result": False,
                    "reason": f"No transition defined for (state={state}, symbol={cur_symbol}) at step {steps}.",
                    "steps": steps,
                    "trace": trace,
                }

            next_state, write_sym, move_dir = self.transitions[key]
            # record action in trace last entry
            trace[-1].update({"action": f"write '{write_sym}', move {move_dir}, next_state={next_state}"})

            tape.write(write_sym)
            tape.move(move_dir)
            state = next_state
            steps += 1

        return {
            "error": False,
            "result": False,
            "reason": f"Exceeded max steps ({max_steps}). Possible infinite loop.",
            "steps": steps,
            "trace": trace,
        }
