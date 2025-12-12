#!/usr/bin/env python3
import argparse
import sys
from turing_machine.core import TuringMachine
from turing_machine.machines import get_machine


def build_tm_from_def(defn):
    return TuringMachine(
        states=defn['states'],
        input_symbols=defn['input_symbols'],
        tape_symbols=defn['tape_symbols'],
        blank_symbol=defn['blank'],
        transitions=defn['transitions'],
        start_state=defn['start_state'],
        accept_states=defn['accept_states'],
        reject_states=defn['reject_states'],
    )


def print_trace(result):
    if result.get('error'):
        print('Error:', result.get('message'))
        return

    trace = result.get('trace', [])
    for step in trace:
        s = step
        print(f"Step {s['step']}: state={s['state']}, head={s['head']}, tape={s['tape']}")
        if 'action' in s:
            print(f"  action: {s['action']}")

    if result.get('result'):
        print('\nRESULT: ACCEPT (PASS)')
    else:
        print('\nRESULT: REJECT (FAIL)')
    print('Reason:', result.get('reason'))


def interactive_mode(machine_name):
    try:
        defn = get_machine(machine_name)
    except Exception as e:
        print('Unknown machine', machine_name)
        return
    tm = build_tm_from_def(defn)

    while True:
        s = input('Enter input string (or blank to quit): ')
        if s == '':
            print('Goodbye')
            break
        res = tm.run(s)
        print_trace(res)


def main():
    parser = argparse.ArgumentParser(description='Turing Machine Simulator')
    parser.add_argument('--machine', default='equal-zeros-ones', help='which machine to use')
    parser.add_argument('--input', help='input string for the machine')
    args = parser.parse_args()

    try:
        defn = get_machine(args.machine)
    except Exception as e:
        print('Error:', e)
        sys.exit(2)

    tm = build_tm_from_def(defn)

    if args.input is None:
        print('Interactive mode. Machine:', args.machine)
        interactive_mode(args.machine)
        return

    result = tm.run(args.input)
    print_trace(result)


if __name__ == '__main__':
    main()
