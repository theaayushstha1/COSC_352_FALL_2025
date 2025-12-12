#include "turing_machine.h"
#include "examples.cpp"
#include <iostream>
#include <string>
#include <vector>

void print_menu() {
    std::cout << "\n╔════════════════════════════════════════════════════════════════╗\n";
    std::cout << "║           TURING MACHINE SIMULATOR - C++                       ║\n";
    std::cout << "╚════════════════════════════════════════════════════════════════╝\n\n";
    std::cout << "Select a Turing Machine to simulate:\n\n";
    std::cout << "  1. Binary Palindrome Checker\n";
    std::cout << "     Accepts palindromes over {0,1}\n";
    std::cout << "     Examples: \"\", \"0\", \"1\", \"010\", \"1001\"\n\n";
    std::cout << "  2. a^n b^n Recognizer\n";
    std::cout << "     Accepts strings of form a^n b^n (n >= 1)\n";
    std::cout << "     Examples: \"ab\", \"aabb\", \"aaabbb\"\n\n";
    std::cout << "  3. Binary Incrementer\n";
    std::cout << "     Adds 1 to a binary number\n";
    std::cout << "     Examples: \"0\"→\"1\", \"111\"→\"1000\"\n\n";
    std::cout << "  4. Even Number of 1's Checker\n";
    std::cout << "     Accepts strings with even count of 1's\n";
    std::cout << "     Examples: \"\", \"00\", \"11\", \"0110\"\n\n";
    std::cout << "  5. Run All Demo Tests\n\n";
    std::cout << "  0. Exit\n\n";
    std::cout << "Enter choice: ";
}

void interactive_mode(TuringMachine* tm, const std::string& name) {
    std::cout << "\n╔════════════════════════════════════════════════════════════════╗\n";
    std::cout << "║  " << name << std::string(62 - name.length(), ' ') << "║\n";
    std::cout << "╚════════════════════════════════════════════════════════════════╝\n";
    std::cout << "\nEnter input string (or 'q' to quit): ";
    
    std::string input;
    while (std::getline(std::cin, input)) {
        if (input == "q" || input == "quit") {
            break;
        }
        
        bool result = tm->run(input);
        
        std::cout << tm->get_trace_string();
        std::cout << tm->get_result_summary();
        
        std::cout << "\nEnter input string (or 'q' to quit): ";
    }
    
    delete tm;
}

int main() {
    while (true) {
        print_menu();
        
        int choice;
        std::cin >> choice;
        std::cin.ignore();  // Clear newline
        
        TuringMachine* tm = nullptr;
        
        switch (choice) {
            case 0:
                std::cout << "\nExiting. Thank you!\n";
                return 0;
            
            case 1:
                tm = create_palindrome_checker();
                interactive_mode(tm, "Binary Palindrome Checker");
                break;
            
            case 2:
                tm = create_anbn_recognizer();
                interactive_mode(tm, "a^n b^n Recognizer");
                break;
            
            case 3:
                tm = create_binary_incrementer();
                interactive_mode(tm, "Binary Incrementer");
                break;
            
            case 4:
                tm = create_even_ones_checker();
                interactive_mode(tm, "Even Number of 1's Checker");
                break;
            
            case 5:
                std::cout << "\nRunning all demo tests...\n";
                
                run_example(create_palindrome_checker(),
                           "Binary Palindrome Checker",
                           {"", "0", "1", "010", "101", "0110", "1001", "100"});
                
                run_example(create_anbn_recognizer(),
                           "a^n b^n Recognizer",
                           {"ab", "aabb", "aaabbb", "a", "b", "aab", "abb"});
                
                run_example(create_binary_incrementer(),
                           "Binary Incrementer",
                           {"0", "1", "10", "11", "101", "111"});
                
                run_example(create_even_ones_checker(),
                           "Even Number of 1's Checker",
                           {"", "0", "1", "00", "11", "0110", "111"});
                
                break;
            
            default:
                std::cout << "\nInvalid choice. Please try again.\n";
        }
    }
    
    return 0;
}