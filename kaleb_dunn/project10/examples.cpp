#include "turing_machine.h"
#include <iostream>

/**
 * Example 1: Binary Palindrome Checker
 * Accepts strings that are palindromes over {0,1}
 * Examples: "", "0", "1", "00", "11", "010", "101", "0110"
 */
TuringMachine* create_palindrome_checker() {
    auto* tm = new TuringMachine("q0", '_');
    
    // Mark and check ends
    tm->add_transition("q0", '0', "q1", 'X', 'R');  // Mark first 0
    tm->add_transition("q0", '1', "q2", 'X', 'R');  // Mark first 1
    tm->add_transition("q0", '_', "accept", '_', 'S');  // Empty string
    tm->add_transition("q0", 'X', "q0", 'X', 'R');  // Skip marked
    
    // After marking '0', find matching '0' at end
    tm->add_transition("q1", '0', "q1", '0', 'R');
    tm->add_transition("q1", '1', "q1", '1', 'R');
    tm->add_transition("q1", 'Y', "q1", 'Y', 'R');
    tm->add_transition("q1", '_', "q3", '_', 'L');  // Found end
    
    // Check last symbol is '0'
    tm->add_transition("q3", '0', "q4", 'Y', 'L');  // Match found
    tm->add_transition("q3", 'Y', "q3", 'Y', 'L');  // Skip marked
    tm->add_transition("q3", 'X', "accept", 'X', 'S');  // All matched
    
    // After marking '1', find matching '1' at end
    tm->add_transition("q2", '0', "q2", '0', 'R');
    tm->add_transition("q2", '1', "q2", '1', 'R');
    tm->add_transition("q2", 'Y', "q2", 'Y', 'R');
    tm->add_transition("q2", '_', "q5", '_', 'L');  // Found end
    
    // Check last symbol is '1'
    tm->add_transition("q5", '1', "q4", 'Y', 'L');  // Match found
    tm->add_transition("q5", 'Y', "q5", 'Y', 'L');  // Skip marked
    tm->add_transition("q5", 'X', "accept", 'X', 'S');  // All matched
    
    // Go back to beginning
    tm->add_transition("q4", '0', "q4", '0', 'L');
    tm->add_transition("q4", '1', "q4", '1', 'L');
    tm->add_transition("q4", 'X', "q4", 'X', 'L');
    tm->add_transition("q4", 'Y', "q4", 'Y', 'L');
    tm->add_transition("q4", '_', "q0", '_', 'R');  // Back to start
    
    tm->add_accept_state("accept");
    tm->add_reject_state("reject");
    
    return tm;
}

/**
 * Example 2: a^n b^n Recognizer
 * Accepts strings of form a^n b^n where n >= 1
 * Examples: "ab", "aabb", "aaabbb", "aaaabbbb"
 */
TuringMachine* create_anbn_recognizer() {
    auto* tm = new TuringMachine("q0", '_');
    
    // Mark one 'a' and find matching 'b'
    tm->add_transition("q0", 'a', "q1", 'X', 'R');  // Mark first a
    tm->add_transition("q0", 'Y', "q3", 'Y', 'R');  // Skip marked b's
    tm->add_transition("q0", '_', "reject", '_', 'S');  // Empty
    
    // Find first unmarked 'b'
    tm->add_transition("q1", 'a', "q1", 'a', 'R');
    tm->add_transition("q1", 'Y', "q1", 'Y', 'R');
    tm->add_transition("q1", 'b', "q2", 'Y', 'L');  // Mark matching b
    
    // Go back to start
    tm->add_transition("q2", 'a', "q2", 'a', 'L');
    tm->add_transition("q2", 'Y', "q2", 'Y', 'L');
    tm->add_transition("q2", 'X', "q2", 'X', 'L');
    tm->add_transition("q2", '_', "q0", '_', 'R');
    
    // Check if all matched
    tm->add_transition("q3", 'Y', "q3", 'Y', 'R');
    tm->add_transition("q3", '_', "accept", '_', 'S');  // All matched!
    
    tm->add_accept_state("accept");
    tm->add_reject_state("reject");
    
    return tm;
}

/**
 * Example 3: Binary Increment Machine
 * Adds 1 to a binary number
 * Examples: "0" -> "1", "1" -> "10", "101" -> "110", "111" -> "1000"
 */
TuringMachine* create_binary_incrementer() {
    auto* tm = new TuringMachine("q0", '_');
    
    // Move to rightmost digit
    tm->add_transition("q0", '0', "q0", '0', 'R');
    tm->add_transition("q0", '1', "q0", '1', 'R');
    tm->add_transition("q0", '_', "q1", '_', 'L');  // Found end
    
    // Increment (handle carry)
    tm->add_transition("q1", '0', "accept", '1', 'S');  // 0 -> 1, done
    tm->add_transition("q1", '1', "q1", '0', 'L');  // 1 -> 0, carry
    tm->add_transition("q1", '_', "q2", '1', 'S');  // Carry to new digit
    
    // Inserted new leading 1
    tm->add_transition("q2", '1', "accept", '1', 'S');
    
    tm->add_accept_state("accept");
    
    return tm;
}

/**
 * Example 4: Even Number of 1's
 * Accepts strings with even number of 1's (including zero 1's)
 * Examples: "", "0", "00", "11", "0110", "1001"
 */
TuringMachine* create_even_ones_checker() {
    auto* tm = new TuringMachine("q_even", '_');
    
    // Even state
    tm->add_transition("q_even", '0', "q_even", '0', 'R');
    tm->add_transition("q_even", '1', "q_odd", '1', 'R');
    tm->add_transition("q_even", '_', "accept", '_', 'S');
    
    // Odd state
    tm->add_transition("q_odd", '0', "q_odd", '0', 'R');
    tm->add_transition("q_odd", '1', "q_even", '1', 'R');
    tm->add_transition("q_odd", '_', "reject", '_', 'S');
    
    tm->add_accept_state("accept");
    tm->add_reject_state("reject");
    
    return tm;
}

void run_example(TuringMachine* tm, const std::string& name,
                const std::vector<std::string>& test_inputs) {
    std::cout << "\n═══════════════════════════════════════════════════════════════\n";
    std::cout << " " << name << "\n";
    std::cout << "═══════════════════════════════════════════════════════════════\n";
    
    for (const auto& input : test_inputs) {
        std::cout << "\nTesting input: \"" << input << "\"\n";
        std::cout << "───────────────────────────────────────────────────────────────\n";
        
        bool result = tm->run(input);
        
        std::cout << tm->get_trace_string();
        std::cout << tm->get_result_summary();
        
        std::cout << (result ? "✓ PASS" : "✗ FAIL") << "\n";
        std::cout << "═══════════════════════════════════════════════════════════════\n";
    }
    
    delete tm;
}