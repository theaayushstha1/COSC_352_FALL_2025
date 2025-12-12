#!/usr/bin/env python3
"""
Web Interface for Turing Machine Simulator using Flask
"""

from flask import Flask, render_template, request, jsonify
from turing_machine import (
    create_simple_tm,
    create_binary_palindrome_tm,
    create_balanced_parentheses_tm
)

app = Flask(__name__)


@app.route('/')
def index():
    return render_template('index.html')


@app.route('/api/simulate', methods=['POST'])
def simulate():
    """API endpoint to run Turing Machine simulation"""
    try:
        data = request.get_json()
        complexity = data.get('complexity', 'medium')
        input_string = data.get('input', '')
        
        # Create appropriate Turing Machine
        if complexity == 'easy':
            tm = create_simple_tm()
            description = "Accepts strings with equal number of 0s and 1s"
        elif complexity == 'medium':
            tm = create_binary_palindrome_tm()
            description = "Accepts binary strings that are palindromes"
        else:  # hard
            tm = create_balanced_parentheses_tm()
            description = "Accepts strings with balanced parentheses"
        
        # Run simulation
        accepted, trace, reason = tm.run(input_string)
        
        # Format response
        response = {
            'success': True,
            'input': input_string,
            'complexity': complexity,
            'description': description,
            'accepted': accepted,
            'reason': reason,
            'steps': len(trace) - 1,
            'trace': trace
        }
        
        return jsonify(response)
    
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 400


@app.route('/api/info', methods=['GET'])
def info():
    """Get information about available Turing Machines"""
    return jsonify({
        'machines': {
            'easy': {
                'name': 'Equal 0s and 1s',
                'description': 'Accepts strings with equal number of 0s and 1s',
                'examples': {
                    'valid': ['01', '0011', '1100', '0101'],
                    'invalid': ['0', '1', '001', '111']
                }
            },
            'medium': {
                'name': 'Binary Palindrome',
                'description': 'Accepts binary strings that read the same forwards and backwards',
                'examples': {
                    'valid': ['0', '1', '11', '101', '1001', '10101'],
                    'invalid': ['10', '110', '1000', '10110']
                }
            },
            'hard': {
                'name': 'Balanced Parentheses',
                'description': 'Accepts strings with properly balanced parentheses',
                'examples': {
                    'valid': ['()', '(())', '()()', '((()))'],
                    'invalid': ['(', ')', ')(', '(()']
                }
            }
        }
    })


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)