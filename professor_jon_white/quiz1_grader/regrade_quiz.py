#!/usr/bin/env python3
"""
Script to re-grade a student's quiz using the already-extracted text from the JSON file.
This is much faster and cheaper than re-processing the image since it only sends text to GPT-5.

Usage:
  python regrade_quiz.py student_response.json
  python regrade_quiz.py data/IMG_8863.json
"""

from openai import OpenAI
import sys
import json
import os
import time
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()


def read_existing_json(json_file):
    """Read and validate the existing JSON file."""
    if not os.path.exists(json_file):
        print(f"Error: File '{json_file}' not found.")
        sys.exit(1)

    try:
        with open(json_file, 'r') as f:
            data = json.load(f)
        return data
    except json.JSONDecodeError as e:
        print(f"Error: Could not parse JSON file: {e}")
        sys.exit(1)
    except Exception as e:
        print(f"Error: Could not read file: {e}")
        sys.exit(1)


def read_grading_instructions(instructions_file='grading_instructions.md'):
    """Read the grading instructions from the markdown file."""
    script_dir = os.path.dirname(os.path.abspath(__file__))
    instructions_path = os.path.join(script_dir, instructions_file)

    if not os.path.exists(instructions_path):
        print(f"Error: Grading instructions file '{instructions_path}' not found.")
        sys.exit(1)

    with open(instructions_path, 'r') as f:
        return f.read()


def load_student_roster(roster_file='student_roster.json'):
    """Load the student roster for name matching."""
    script_dir = os.path.dirname(os.path.abspath(__file__))
    roster_path = os.path.join(script_dir, roster_file)

    if not os.path.exists(roster_path):
        print(f"Warning: Student roster file '{roster_path}' not found.")
        return []

    try:
        with open(roster_path, 'r') as f:
            return json.load(f)
    except Exception as e:
        print(f"Warning: Could not load student roster: {e}")
        return []


def main():
    # Check command line arguments
    if len(sys.argv) < 2:
        print("Usage: python regrade_quiz.py <student_response.json>")
        sys.exit(1)

    json_file = sys.argv[1]

    # Read existing JSON
    print(f"Reading existing JSON file: {json_file}")
    existing_data = read_existing_json(json_file)

    # Extract the answer text
    answer_text = existing_data.get('answer_text', '')
    student_name = existing_data.get('name', 'Unknown Student')

    if not answer_text:
        print("Error: No 'answer_text' field found in JSON file.")
        print("This file may not have been processed yet. Use grade_quiz.py instead.")
        sys.exit(1)

    print(f"Re-grading for: {student_name}")
    print(f"Answer text length: {len(answer_text)} characters")

    # Read grading instructions
    print("Reading grading instructions...")
    grading_instructions = read_grading_instructions()

    # Load student roster
    print("Loading student roster...")
    student_roster = load_student_roster()

    # Initialize OpenAI client
    client = OpenAI()

    # Send to GPT-5 for re-grading (text only, no image)
    print("Sending extracted text to GPT-5 for re-grading...")

    # Build student list for prompt
    if student_roster:
        student_list = "\n".join([f"- {s['name']} (login: {s['login_id']})" for s in student_roster])
        name_matching_instructions = f"""

STUDENT NAME MATCHING:
The student's name is currently: "{student_name}"
The following is a list of students enrolled in this course:
{student_list}

Please match the student name to the roster:
1. Keep the "name" field as "{student_name}" (the already extracted name)
2. ONLY if you are HIGHLY CONFIDENT (>90% sure) about a match, store the matched student's name in "matched_name" and their "login_id"
3. If the match confidence is low or no clear match exists, set both "matched_name" and "login_id" to null
4. DO NOT make guesses - it's better to have no match than a false positive
"""
        json_schema_addition = """
"name": "Keep as '{student_name}'",
"matched_name": "Roster name if >90% confident match, otherwise null",
"login_id": "Login ID if >90% confident match, otherwise null",
""".format(student_name=student_name)
    else:
        name_matching_instructions = ""
        json_schema_addition = f"""
"name": "{student_name}",
"""

    # Modified prompt for text-based grading
    prompt = f"""The student's response to the quiz question is provided below as text (already extracted from their handwritten submission). Please grade it according to the following instructions:

{grading_instructions}
{name_matching_instructions}

IMPORTANT INSTRUCTIONS:
1. The student's response is already transcribed below - do NOT modify the answer_text
2. Use the EXACT same answer_text in your JSON response
3. Grade each of the five parts according to the rubric (20 points each)
4. Each question should be either 0 points - for completely incorrect, 10 points - for partially correct, and 20 points - for fully correct and great answer. No values outside of 0,10,20.
5. Provide detailed, constructive feedback for each question and why it was either completely incorrect, partially correct or fully correct.
6. Calculate the total score
7. Provide overall feedback summarizing strengths and areas for improvement

STUDENT'S ANSWER TEXT:
{answer_text}

Your JSON response must include these fields at the top level:
{{
{json_schema_addition}"answer_text": "Full transcribed response",
"scores": {{...}},
"total_score": 0-100,
"overall_feedback": "..."
}}

CRITICAL: Return ONLY valid JSON, no additional text or explanation outside the JSON structure."""

    # Start timing the API call
    start_time = time.time()

    response = client.responses.create(
        model="gpt-5",
        input=[
            {
                "role": "user",
                "content": [
                    {
                        "type": "input_text",
                        "text": prompt,
                    }
                ]
            }
        ]
    )

    # Calculate elapsed time
    elapsed_time = time.time() - start_time
    print(f"✓ Re-grading completed in {elapsed_time:.2f} seconds")

    # Try to parse the response as JSON
    try:
        json_response = json.loads(response.output_text)

        # Add grading time to the response
        json_response['grading_time_seconds'] = round(elapsed_time, 2)

        # Ensure the answer_text matches the original (in case GPT modified it)
        json_response['answer_text'] = answer_text

        # Save to file, overwriting the original
        with open(json_file, 'w') as f:
            json.dump(json_response, f, indent=2)
        print(f"✓ Re-grading results saved to: {json_file}")

        # Pretty print the JSON
        print("\n" + "="*50)
        print("Re-Grading Results:")
        print("="*50)
        print(json.dumps(json_response, indent=2))

        if 'total_score' in json_response:
            print(f"\nTotal Score: {json_response['total_score']}/100")
            print(f"Re-grading Time: {elapsed_time:.2f} seconds")

    except json.JSONDecodeError:
        # If response isn't valid JSON, print raw response
        print("\n" + "="*50)
        print("Raw Response (couldn't parse as JSON):")
        print("="*50)
        print(response.output_text)
        print("\nWarning: Could not parse response as JSON. Original file not modified.")

    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
