#include <iostream>
#include <vector>
#include <string>
#include <map>
#include <tuple>
#include <algorithm>
#include <sstream>

using namespace std;

// --- Turing Machine Definition ---
// Strategy: Ping-Pong Palindrome Check
// 1. Read Leftmost Unmarked -> Mark 'X' -> Go Right -> Match with Rightmost Unmarked -> Mark 'Y'
// 2. Read Rightmost Unmarked -> Mark 'Y' -> Go Left -> Match with Leftmost Unmarked -> Mark 'X'
// 3. Repeat until markers meet.

const char BLANK_SYMBOL = ' ';
const string ACCEPT_STATE = "q_pass"; // Intermediate success state
const string REJECT_STATE = "q_fail"; // Intermediate fail state
const int MAX_STEPS = 5000;

// Transition Key: (Current State, Symbol)
// Transition Value: (New State, New Symbol, Move Direction)
using TransitionMap = map<tuple<string, char>, tuple<string, char, char>>;

const TransitionMap TRANSITIONS = {
    // -----------------------------------------------------------------------
    // PHASE 1: START (Left to Right)
    // -----------------------------------------------------------------------
    // q_start: Start logic. Look for the first symbol to Process (Left side).
    {{"q_start", '0'},          {"q_save_L_0", 'X', 'R'}}, // Found 0 on Left. Save '0', Mark X, Go Right.
    {{"q_start", '1'},          {"q_save_L_1", 'X', 'R'}}, // Found 1 on Left. Save '1', Mark X, Go Right.
    {{"q_start", 'Y'},          {ACCEPT_STATE, 'Y', 'S'}}, // Hit a Y immediately? All pairs matched (Odd length case). Success.
    {{"q_start", BLANK_SYMBOL}, {ACCEPT_STATE, BLANK_SYMBOL, 'S'}}, // Empty tape or done. Success.

    // -----------------------------------------------------------------------
    // PHASE 2: TRAVEL RIGHT (Looking for match for Left Bit)
    // -----------------------------------------------------------------------
    // q_save_L_0: We read a '0' on the left. Travel Right to find the end.
    {{"q_save_L_0", '0'},          {"q_save_L_0", '0', 'R'}}, // Skip 0
    {{"q_save_L_0", '1'},          {"q_save_L_0", '1', 'R'}}, // Skip 1
    {{"q_save_L_0", 'Y'},          {"q_chk_L_0", 'Y', 'L'}}, // Hit Y (end of unmatched). Check neighbor on Left.
    {{"q_save_L_0", BLANK_SYMBOL}, {"q_chk_L_0", BLANK_SYMBOL, 'L'}}, // Hit End of Tape. Check neighbor on Left.

    // q_save_L_1: We read a '1' on the left. Travel Right.
    {{"q_save_L_1", '0'},          {"q_save_L_1", '0', 'R'}}, 
    {{"q_save_L_1", '1'},          {"q_save_L_1", '1', 'R'}}, 
    {{"q_save_L_1", 'Y'},          {"q_chk_L_1", 'Y', 'L'}}, 
    {{"q_save_L_1", BLANK_SYMBOL}, {"q_chk_L_1", BLANK_SYMBOL, 'L'}}, 

    // -----------------------------------------------------------------------
    // PHASE 3: CHECK MATCH (Right Side)
    // -----------------------------------------------------------------------
    // q_chk_L_0: We expect a '0' here.
    {{"q_chk_L_0", '0'}, {"q_read_R", 'Y', 'L'}}, // Match! Mark Y. Switch to "Ready to Read Right".
    {{"q_chk_L_0", '1'}, {REJECT_STATE, '1', 'S'}},      // Mismatch! Fail.
    {{"q_chk_L_0", 'X'}, {ACCEPT_STATE, 'X', 'S'}},      // Hit X? This was the middle char (Odd length). Success.

    // q_chk_L_1: We expect a '1' here.
    {{"q_chk_L_1", '1'}, {"q_read_R", 'Y', 'L'}}, // Match! Mark Y. Switch to "Ready to Read Right".
    {{"q_chk_L_1", '0'}, {REJECT_STATE, '0', 'S'}},      // Mismatch! Fail.
    {{"q_chk_L_1", 'X'}, {ACCEPT_STATE, 'X', 'S'}},      // Hit X? Middle char. Success.

    // -----------------------------------------------------------------------
    // PHASE 4: START (Right to Left)
    // -----------------------------------------------------------------------
    // q_read_R: We are on the Right side (just marked a Y). Move Left 1 step to read next bit.
    // Actually, after marking Y and moving L (in Phase 3), we are ON the bit we want to read.
    // So we can transition directly from Phase 3 to "Reading" states if we structure it carefully.
    // Let's create a specific state "q_read_R" that decides what to save.
    
    {{"q_read_R", '0'}, {"q_save_R_0", 'Y', 'L'}}, // Read '0' on Right. Save '0', Mark Y, Go Left.
    {{"q_read_R", '1'}, {"q_save_R_1", 'Y', 'L'}}, // Read '1' on Right. Save '1', Mark Y, Go Left.
    {{"q_read_R", 'X'}, {ACCEPT_STATE, 'X', 'S'}}, // Hit X? We met in the middle. Success.

    // -----------------------------------------------------------------------
    // PHASE 5: TRAVEL LEFT (Looking for match for Right Bit)
    // -----------------------------------------------------------------------
    // q_save_R_0: We read '0' on Right. Travel Left to find X.
    {{"q_save_R_0", '0'}, {"q_save_R_0", '0', 'L'}}, 
    {{"q_save_R_0", '1'}, {"q_save_R_0", '1', 'L'}}, 
    {{"q_save_R_0", 'X'}, {"q_chk_R_0", 'X', 'R'}}, // Hit X. Check neighbor on Right.

    // q_save_R_1: We read '1' on Right. Travel Left to find X.
    {{"q_save_R_1", '0'}, {"q_save_R_1", '0', 'L'}}, 
    {{"q_save_R_1", '1'}, {"q_save_R_1", '1', 'L'}}, 
    {{"q_save_R_1", 'X'}, {"q_chk_R_1", 'X', 'R'}}, // Hit X. Check neighbor on Right.

    // -----------------------------------------------------------------------
    // PHASE 6: CHECK MATCH (Left Side)
    // -----------------------------------------------------------------------
    // q_chk_R_0: We expect a '0' here.
    {{"q_chk_R_0", '0'}, {"q_start", 'X', 'R'}},      // Match! Mark X. Loop back to q_start (Left Scan Start).
    {{"q_chk_R_0", '1'}, {REJECT_STATE, '1', 'S'}}, // Mismatch. Fail.
    {{"q_chk_R_0", 'Y'}, {ACCEPT_STATE, 'Y', 'S'}}, // Hit Y? Middle char matched. Success.

    // q_chk_R_1: We expect a '1' here.
    {{"q_chk_R_1", '1'}, {"q_start", 'X', 'R'}},      // Match! Mark X. Loop back to q_start.
    {{"q_chk_R_1", '0'}, {REJECT_STATE, '0', 'S'}}, // Mismatch. Fail.
    {{"q_chk_R_1", 'Y'}, {ACCEPT_STATE, 'Y', 'S'}}, // Hit Y? Middle char matched. Success.


    // -----------------------------------------------------------------------
    // PHASE 7: CLEANUP & FINAL WRITE (Pass)
    // -----------------------------------------------------------------------
    // Go to Start (Index 0) and Write '1'
    
    // Logic from q_pass: Start Rewinding Left
    {{ACCEPT_STATE, 'X'},          {"q_rew_pass", ' ', 'L'}},
    {{ACCEPT_STATE, 'Y'},          {"q_rew_pass", ' ', 'L'}},
    {{ACCEPT_STATE, '0'},          {"q_rew_pass", ' ', 'L'}}, // In case odd middle char left
    {{ACCEPT_STATE, '1'},          {"q_rew_pass", ' ', 'L'}}, 
    {{ACCEPT_STATE, BLANK_SYMBOL}, {"q_rew_pass", ' ', 'L'}},

    // Rewind loop
    {{"q_rew_pass", 'X'},          {"q_rew_pass", ' ', 'L'}}, // Clean tape as we go
    {{"q_rew_pass", 'Y'},          {"q_rew_pass", ' ', 'L'}},
    {{"q_rew_pass", '0'},          {"q_rew_pass", ' ', 'L'}},
    {{"q_rew_pass", '1'},          {"q_rew_pass", ' ', 'L'}},
    {{"q_rew_pass", BLANK_SYMBOL}, {"q_halt_pass", '1', 'S'}}, // Hit start (Index -1 blank), write 1 at 0? 
    // Correction: We need to hit blank at -1, then step R to 0, then write.
    // Simplified: If at blank, write 1, done. (Assuming index 0 became blank).

    // -----------------------------------------------------------------------
    // PHASE 8: CLEANUP & FINAL WRITE (Fail)
    // -----------------------------------------------------------------------
    // Logic from q_fail: Start Rewinding Left
    {{REJECT_STATE, 'X'},          {"q_rew_fail", ' ', 'L'}},
    {{REJECT_STATE, 'Y'},          {"q_rew_fail", ' ', 'L'}},
    {{REJECT_STATE, '0'},          {"q_rew_fail", ' ', 'L'}},
    {{REJECT_STATE, '1'},          {"q_rew_fail", ' ', 'L'}},
    {{REJECT_STATE, BLANK_SYMBOL}, {"q_rew_fail", ' ', 'L'}},

    // Rewind loop
    {{"q_rew_fail", 'X'},          {"q_rew_fail", ' ', 'L'}},
    {{"q_rew_fail", 'Y'},          {"q_rew_fail", ' ', 'L'}},
    {{"q_rew_fail", '0'},          {"q_rew_fail", ' ', 'L'}},
    {{"q_rew_fail", '1'},          {"q_rew_fail", ' ', 'L'}},
    {{"q_rew_fail", BLANK_SYMBOL}, {"q_halt_fail", '0', 'S'}},
};


class TuringMachine {
private:
    vector<char> tape;
    int head_position;
    string current_state;
    int step_count;
    string initial_input;

    char getCurrentSymbol() {
        while (head_position >= (int)tape.size()) tape.push_back(BLANK_SYMBOL);
        while (head_position < 0) {
            tape.insert(tape.begin(), BLANK_SYMBOL);
            head_position = 0;
        }
        return tape[head_position];
    }

    void printTrace() {
        // Only print first 20, last 20, and significant state changes to keep output clean
        bool important_state = (current_state == "q_start" || current_state == "q_read_R" || 
                                current_state == ACCEPT_STATE || current_state == REJECT_STATE || 
                                current_state == "q_halt_pass" || current_state == "q_halt_fail");
        
                                
        if (important_state || step_count < 25) {
            vector<char> display = tape;
            stringstream ss;
            int start = max(0, head_position - 15);
            int end = min((int)display.size(), head_position + 15);
            
            for (int i = start; i < end; ++i) {
                if (i == head_position) ss << "[" << display[i] << "]";
                else ss << display[i];
            }
            cout << step_count << "\t| " << current_state
                 << "\t| " << head_position << "\t| " << ss.str() << endl;
        }
    }

public:
    TuringMachine(const string& input_str) : initial_input(input_str) {
        tape.push_back(BLANK_SYMBOL); // Index 0 is blank
        for (char c : input_str) tape.push_back(c);
        head_position = 1; // Start at first char
        current_state = "q_start";
        step_count = 0;
    }

    void run() {
        cout << "\n--- STARTING MACHINE: " << initial_input << " ---" << endl;
        cout << "Step:\t| State:\t| Head:\t| Tape:" << endl;
        cout << "---------------------------------------" << endl;

        while (current_state != "q_halt_pass" && current_state != "q_halt_fail" && step_count < MAX_STEPS) {
            printTrace();
            char sym = getCurrentSymbol();
            auto key = make_tuple(current_state, sym);
            
            if (TRANSITIONS.count(key)) {
                auto val = TRANSITIONS.at(key);
                tape[head_position] = get<1>(val);
                char dir = get<2>(val);
                if (dir == 'R') head_position++;
                else if (dir == 'L') head_position--;
                current_state = get<0>(val);
                step_count++;
            } else {
                // If stuck, assume reject
                current_state = REJECT_STATE;
            }
        }
        printTrace();
        
        // Final Result is at tape[0]
        char result = tape[0]; 
        // Note: Due to rewind logic, tape[0] might be the space we just wrote to
        // Let's ensure we find the result bit.
        // In this implementation, q_halt_pass/fail writes to the blank found at start.
        
        if (current_state == "q_halt_pass") {
             cout << "\nRESULT: PALINDROME (" << initial_input << ")" << endl;
        } else {
             cout << "\nRESULT: NOT PALINDROME (" << initial_input << ")" << endl;
        }
    }
};

int main(int argc, char* argv[]) {
    if (argc != 2) return 1;
    TuringMachine tm(argv[1]);
    tm.run();
    return 0;
}