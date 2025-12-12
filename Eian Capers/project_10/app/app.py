from flask import Flask, render_template, request, jsonify
import sys
import os
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from machines.palindrome import PalindromeTM
from machines.binary_adder import BinaryAdderTM
from machines.balanced_parens import BalancedParensTM

app = Flask(__name__)

# Initialize machines
machines = {
    'palindrome': PalindromeTM(),
    'binary_adder': BinaryAdderTM(),
    'balanced_parens': BalancedParensTM()
}

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/api/machines', methods=['GET'])
def get_machines():
    """Return list of available machines with their descriptions"""
    machine_info = {
        name: {
            'name': machine.name,
            'description': machine.description,
            'examples': machine.examples
        }
        for name, machine in machines.items()
    }
    return jsonify(machine_info)

@app.route('/api/simulate', methods=['POST'])
def simulate():
    """Execute a Turing Machine on given input"""
    data = request.json
    machine_type = data.get('machine', 'palindrome')
    input_string = data.get('input', '')
    
    if machine_type not in machines:
        return jsonify({'error': 'Invalid machine type'}), 400
    
    machine = machines[machine_type]
    
    try:
        result = machine.run(input_string)
        return jsonify(result)
    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)