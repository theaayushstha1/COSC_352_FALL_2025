#!/usr/bin/env node

/**
 * Turing Machine Simulator - JavaScript Implementation
 * Supports both CLI and programmatic usage
 */

const readline = require('readline');

class TuringMachine {
    constructor(config) {
        this.states = config.states;
        this.alphabet = config.alphabet;
        this.transitions = config.transitions;
        this.startState = config.startState;
        this.acceptState = config.acceptState;
        this.rejectState = config.rejectState;
        this.blankSymbol = config.blankSymbol || '_';
        
        // Runtime state
        this.tape = new Map();
        this.headPosition = 0;
        this.currentState = this.startState;
        this.stepCount = 0;
        this.trace = [];
    }
    
    loadInput(input) {
        this.tape = new Map();
        for (let i = 0; i < input.length; i++) {
            this.tape.set(i, input[i]);
        }
        this.headPosition = 0;
        this.currentState = this.startState;
        this.stepCount = 0;
        this.trace = [];
    }
    
    readTape() {
        return this.tape.get(this.headPosition) || this.blankSymbol;
    }
    
    writeTape(symbol) {
        if (symbol === this.blankSymbol) {
            this.tape.delete(this.headPosition);
        } else {
            this.tape.set(this.headPosition, symbol);
        }
    }
    
    moveHead(direction) {
        if (direction === 'L') {
            this.headPosition--;
        } else if (direction === 'R') {
            this.headPosition++;
        }
    }
    
    getTapeString(window = 20) {
        if (this.tape.size === 0) {
            return `[${this.blankSymbol}]`;
        }
        
        const positions = Array.from(this.tape.keys());
        const minPos = Math.min(...positions, this.headPosition - window);
        const maxPos = Math.max(...positions, this.headPosition + window);
        
        let result = '';
        for (let i = minPos; i <= maxPos; i++) {
            const symbol = this.tape.get(i) || this.blankSymbol;
            if (i === this.headPosition) {
                result += `[${symbol}]`;
            } else {
                result += symbol;
            }
        }
        return result;
    }
    
    step() {
        const currentSymbol = this.readTape();
        
        // Record trace
        this.trace.push({
            step: this.stepCount,
            state: this.currentState,
            head: this.headPosition,
            symbol: currentSymbol,
            tape: this.getTapeString()
        });
        
        // Check halting states
        if (this.currentState === this.acceptState || 
            this.currentState === this.rejectState) {
            return false;
        }
        
        // Look up transition
        const key = `${this.currentState},${currentSymbol}`;
        if (!this.transitions[key]) {
            this.currentState = this.rejectState;
            return false;
        }
        
        const [newState, newSymbol, direction] = this.transitions[key];
        
        // Execute transition
        this.writeTape(newSymbol);
        this.currentState = newState;
        this.moveHead(direction);
        this.stepCount++;
        
        return true;
    }
    
    run(input, maxSteps = 1000) {
        this.loadInput(input);
        
        while (this.stepCount < maxSteps) {
            if (!this.step()) break;
        }
        
        return {
            accepted: this.currentState === this.acceptState,
            trace: this.trace,
            steps: this.stepCount,
            finalState: this.currentState
        };
    }
}

// =============================================================================
// PRE-BUILT MACHINES
// =============================================================================

function createBinaryPalindromeChecker() {
    return new TuringMachine({
        states: ['q0', 'q1', 'q2', 'q3', 'q4', 'q5', 'accept', 'reject'],
        alphabet: ['0', '1'],
        startState: 'q0',
        acceptState: 'accept',
        rejectState: 'reject',
        transitions: {
            'q0,0': ['q1', 'X', 'R'],
            'q0,1': ['q2', 'X', 'R'],
            'q0,X': ['q0', 'X', 'R'],
            'q0,_': ['accept', '_', 'S'],
            
            'q1,0': ['q1', '0', 'R'],
            'q1,1': ['q1', '1', 'R'],
            'q1,X': ['q1', 'X', 'R'],
            'q1,_': ['q3', '_', 'L'],
            
            'q3,0': ['q4', 'X', 'L'],
            'q3,X': ['q0', 'X', 'R'],
            
            'q2,0': ['q2', '0', 'R'],
            'q2,1': ['q2', '1', 'R'],
            'q2,X': ['q2', 'X', 'R'],
            'q2,_': ['q5', '_', 'L'],
            
            'q5,1': ['q4', 'X', 'L'],
            'q5,X': ['q0', 'X', 'R'],
            
            'q4,0': ['q4', '0', 'L'],
            'q4,1': ['q4', '1', 'L'],
            'q4,X': ['q4', 'X', 'L'],
            'q4,_': ['q0', '_', 'R']
        }
    });
}

function createBalancedParenthesesChecker() {
    return new TuringMachine({
        states: ['q0', 'q1', 'q2', 'accept', 'reject'],
        alphabet: ['(', ')'],
        startState: 'q0',
        acceptState: 'accept',
        rejectState: 'reject',
        transitions: {
            'q0,(': ['q1', 'X', 'R'],
            'q0,X': ['q0', 'X', 'R'],
            'q0,_': ['accept', '_', 'S'],
            
            'q1,(': ['q1', '(', 'R'],
            'q1,)': ['q2', 'X', 'L'],
            'q1,X': ['q1', 'X', 'R'],
            
            'q2,(': ['q2', '(', 'L'],
            'q2,X': ['q2', 'X', 'L'],
            'q2,_': ['q0', '_', 'R']
        }
    });
}

function createAnBnChecker() {
    return new TuringMachine({
        states: ['q0', 'q1', 'q2', 'accept', 'reject'],
        alphabet: ['a', 'b'],
        startState: 'q0',
        acceptState: 'accept',
        rejectState: 'reject',
        transitions: {
            'q0,a': ['q1', 'X', 'R'],
            'q0,Y': ['q0', 'Y', 'R'],
            'q0,_': ['accept', '_', 'S'],
            
            'q1,a': ['q1', 'a', 'R'],
            'q1,Y': ['q1', 'Y', 'R'],
            'q1,b': ['q2', 'Y', 'L'],
            
            'q2,a': ['q2', 'a', 'L'],
            'q2,Y': ['q2', 'Y', 'L'],
            'q2,X': ['q2', 'X', 'L'],
            'q2,_': ['q0', '_', 'R']
        }
    });
}

// =============================================================================
// CLI INTERFACE
// =============================================================================

const machines = {
    '1': { name: 'Binary Palindrome Checker', creator: createBinaryPalindromeChecker },
    '2': { name: 'Balanced Parentheses Checker', creator: createBalancedParenthesesChecker },
    '3': { name: 'a^n b^n Language', creator: createAnBnChecker }
};

function printMenu() {
    console.log('\n' + '='.repeat(70));
    console.log('TURING MACHINE SIMULATOR');
    console.log('='.repeat(70));
    console.log('\nAvailable Machines:');
    console.log('  1. Binary Palindrome Checker (e.g., "1001", "0110")');
    console.log('  2. Balanced Parentheses Checker (e.g., "(())", "()()")');
    console.log('  3. a^n b^n Language (e.g., "aabb", "aaabbb")');
    console.log('  4. Exit');
    console.log();
}

function printTrace(trace, verbose = true) {
    if (verbose) {
        console.log('\n' + 'Step'.padEnd(6) + 'State'.padEnd(10) + 'Head'.padEnd(6) + 
                    'Symbol'.padEnd(8) + 'Tape');
        console.log('-'.repeat(70));
        trace.forEach(entry => {
            console.log(
                String(entry.step).padEnd(6) +
                entry.state.padEnd(10) +
                String(entry.head).padEnd(6) +
                entry.symbol.padEnd(8) +
                entry.tape
            );
        });
    } else {
        console.log(`\nShowing first and last 5 steps of ${trace.length} total:`);
        console.log('\n' + 'Step'.padEnd(6) + 'State'.padEnd(10) + 'Symbol'.padEnd(8));
        console.log('-'.repeat(30));
        
        trace.slice(0, 5).forEach(entry => {
            console.log(
                String(entry.step).padEnd(6) +
                entry.state.padEnd(10) +
                entry.symbol.padEnd(8)
            );
        });
        
        if (trace.length > 10) {
            console.log('  ...');
        }
        
        trace.slice(-5).forEach(entry => {
            console.log(
                String(entry.step).padEnd(6) +
                entry.state.padEnd(10) +
                entry.symbol.padEnd(8)
            );
        });
    }
    console.log();
}

async function runInteractive() {
    const rl = readline.createInterface({
        input: process.stdin,
        output: process.stdout
    });
    
    const question = (query) => new Promise(resolve => rl.question(query, resolve));
    
    while (true) {
        printMenu();
        const choice = await question('Select a machine (1-4): ');
        
        if (choice === '4') {
            console.log('\nGoodbye!');
            rl.close();
            break;
        }
        
        if (!machines[choice]) {
            console.log('\nInvalid choice. Please try again.');
            continue;
        }
        
        const { name, creator } = machines[choice];
        console.log('\n' + '='.repeat(70));
        console.log(`Selected: ${name}`);
        console.log('='.repeat(70));
        
        const input = await question('\nEnter input string (or "back" to return): ');
        
        if (input.toLowerCase() === 'back') {
            continue;
        }
        
        console.log('\n' + '='.repeat(70));
        console.log(`Running Turing Machine on input: '${input}'`);
        console.log('='.repeat(70));
        
        const tm = creator();
        const result = tm.run(input);
        
        const verbose = result.trace.length <= 50;
        printTrace(result.trace, verbose);
        
        console.log('='.repeat(70));
        if (result.accepted) {
            console.log(`✓ ACCEPTED - Input '${input}' is in the language`);
        } else {
            console.log(`✗ REJECTED - Input '${input}' is NOT in the language`);
        }
        console.log(`Total steps: ${result.steps}`);
        console.log(`Final state: ${result.finalState}`);
        console.log('='.repeat(70));
        
        await question('\nPress Enter to continue...');
    }
}

function runTests() {
    console.log('Running automated tests...\n');
    
    // Test 1: Palindrome
    console.log('Test 1: Binary Palindrome');
    let tm = createBinaryPalindromeChecker();
    ['101', '1001', '110', ''].forEach(test => {
        const result = tm.run(test);
        console.log(`  '${test}': ${result.accepted ? 'PASS' : 'FAIL'}`);
    });
    
    // Test 2: Parentheses
    console.log('\nTest 2: Balanced Parentheses');
    tm = createBalancedParenthesesChecker();
    ['()', '(())', '(()', ''].forEach(test => {
        const result = tm.run(test);
        console.log(`  '${test}': ${result.accepted ? 'PASS' : 'FAIL'}`);
    });
    
    // Test 3: a^n b^n
    console.log('\nTest 3: a^n b^n');
    tm = createAnBnChecker();
    ['ab', 'aabb', 'aaabbb', 'aab', ''].forEach(test => {
        const result = tm.run(test);
        console.log(`  '${test}': ${result.accepted ? 'PASS' : 'FAIL'}`);
    });
}

// Main entry point
if (require.main === module) {
    if (process.argv[2] === '--test') {
        runTests();
    } else {
        runInteractive();
    }
}

// Export for web server
module.exports = {
    TuringMachine,
    createBinaryPalindromeChecker,
    createBalancedParenthesesChecker,
    createAnBnChecker
};