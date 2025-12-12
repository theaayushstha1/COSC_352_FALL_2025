from typing import Dict, Tuple

# Define a sample non-trivial Turing Machine: checks language {0^n1^n | n >= 0}
# Approach: Mark a 0 as X, find rightmost unmarked 1 and mark as Y, return left to find next 0.

def equal_zeros_ones_machine():
    states = [
        'q_start',
        'q_find_1',
        'q_return',
        'q_check_done',
        'q_accept',
        'q_reject',
    ]

    input_symbols = ['0', '1']
    tape_symbols = ['0', '1', 'X', 'Y', '_']
    blank = '_'

    # transitions: (state, symbol) -> (next_state, write_symbol, move)
    # This TM follows a classic algorithm.
    T: Dict[Tuple[str, str], Tuple[str, str, str]] = {}

    # If start sees blank => accept (empty string is in language)
    T[('q_start', blank)] = ('q_accept', blank, 'N')

    # At start, if see X (already marked 0), skip right to check
    T[('q_start', 'X')] = ('q_start', 'X', 'R')

    # At start, if see 0: mark it X and go find a 1 to mark
    T[('q_start', '0')] = ('q_find_1', 'X', 'R')

    # At start, if see Y (already marked 1), it might be middle; skip
    T[('q_start', 'Y')] = ('q_start', 'Y', 'R')

    # If start sees 1 (but no 0 left) -> reject (a leading 1 can't be matched)
    T[('q_start', '1')] = ('q_reject', '1', 'N')

    # q_find_1: move right to find an unmarked 1
    T[('q_find_1', '0')] = ('q_find_1', '0', 'R')
    T[('q_find_1', 'X')] = ('q_find_1', 'X', 'R')
    T[('q_find_1', 'Y')] = ('q_find_1', 'Y', 'R')
    T[('q_find_1', '1')] = ('q_return', 'Y', 'L')  # mark the first 1 encountered
    T[('q_find_1', blank)] = ('q_reject', blank, 'N')

    # q_return: go back left to find next unmarked 0 (or X) — stop at X or Y
    T[('q_return', '0')] = ('q_return', '0', 'L')
    T[('q_return', '1')] = ('q_return', '1', 'L')
    T[('q_return', 'Y')] = ('q_return', 'Y', 'L')
    T[('q_return', 'X')] = ('q_start', 'X', 'R')
    T[('q_return', blank)] = ('q_start', blank, 'R')

    # Once all 0s are marked, q_start will skip X and Y; when it sees blank -> accept

    accept_states = ['q_accept']
    reject_states = ['q_reject']

    return {
        'states': states,
        'input_symbols': input_symbols,
        'tape_symbols': tape_symbols,
        'blank': blank,
        'transitions': T,
        'start_state': 'q_start',
        'accept_states': accept_states,
        'reject_states': reject_states,
        'description': "Checks language {0^n1^n}: marks matching 0s and 1s",
    }


def get_machine(name: str):
    if name in ('equal-zeros-ones', '0n1n', 'equal'):
        return equal_zeros_ones_machine()
    raise ValueError(f"Unknown machine '{name}'")
