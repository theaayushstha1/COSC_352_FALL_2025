#!/usr/bin/env python3
"""
Script to send a HEIC image containing a student's handwritten quiz response to GPT-5 for grading.
Returns structured JSON with scores and feedback.
Caches results to avoid redundant API calls.

Usage:
  python grade_quiz.py student_response.heic
  python grade_quiz.py student_response.heic --force-run
"""

from openai import OpenAI
import base64
import sys
import json
import os
import time
from PIL import Image
from pillow_heif import register_heif_opener
import io
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

# Register HEIF opener with PIL to handle HEIC files
register_heif_opener()

def convert_heic_to_base64(heic_path):
    """Convert HEIC file to base64-encoded JPEG."""
    # Open HEIC file
    img = Image.open(heic_path)

    # Convert to RGB if necessary (HEIC might have alpha channel)
    if img.mode != 'RGB':
        img = img.convert('RGB')

    # Save to bytes buffer as JPEG
    buffer = io.BytesIO()
    img.save(buffer, format='JPEG', quality=95)
    buffer.seek(0)

    # Encode to base64
    return base64.b64encode(buffer.read()).decode('utf-8')

def convert_heic_to_png(heic_path):
    """Convert HEIC file to PNG and save in the same directory."""
    # Open HEIC file
    img = Image.open(heic_path)

    # Convert to RGB if necessary (HEIC might have alpha channel)
    if img.mode != 'RGB':
        img = img.convert('RGB')

    # Generate PNG filename
    png_path = heic_path.rsplit('.', 1)[0] + '.png'

    # Save as PNG
    img.save(png_path, format='PNG')
    print(f"✓ Saved PNG version: {png_path}")

    return png_path

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
        print("Usage: python grade_quiz.py <student_response.heic> [--force-run]")
        sys.exit(1)

    heic_file = sys.argv[1]
    force_run = '--force-run' in sys.argv

    # Check if file exists
    if not os.path.exists(heic_file):
        print(f"Error: File '{heic_file}' not found.")
        sys.exit(1)

    # Generate output filename
    output_file = heic_file.rsplit('.', 1)[0] + '.json'

    # Check if JSON already exists
    if os.path.exists(output_file) and not force_run:
        print(f"Found existing grading results: {output_file}")
        print("Loading cached results...")

        try:
            with open(output_file, 'r') as f:
                json_response = json.load(f)

            # Display the cached results
            print("\n" + "="*50)
            print("Grading Results (Cached):")
            print("="*50)
            print(json.dumps(json_response, indent=2))

            if 'total_score' in json_response:
                print(f"\nTotal Score: {json_response['total_score']}/100")
            if 'grading_time_seconds' in json_response:
                print(f"Grading Time: {json_response['grading_time_seconds']} seconds")

            print(f"\n✓ Results loaded from cache: {output_file}")
            print("To force re-grading, run with --force-run flag")
            return

        except json.JSONDecodeError:
            print(f"Warning: Cached file {output_file} is corrupted. Running new grading...")
        except Exception as e:
            print(f"Warning: Could not read cached file: {e}. Running new grading...")

    # If --force-run flag is present, notify user
    if force_run and os.path.exists(output_file):
        print(f"Force run enabled. Overwriting existing file: {output_file}")

    try:
        # Convert HEIC to base64
        print(f"Converting {heic_file} to base64...")
        image_base64 = convert_heic_to_base64(heic_file)

        # Convert HEIC to PNG and save
        print(f"Converting {heic_file} to PNG...")
        convert_heic_to_png(heic_file)

        # Read grading instructions
        print("Reading grading instructions...")
        grading_instructions = read_grading_instructions()

        # Load student roster
        print("Loading student roster...")
        student_roster = load_student_roster()

        # Initialize OpenAI client
        client = OpenAI()

        # Send to GPT-5 for grading
        print("Sending image to GPT-5 for grading...")

        # Create base64 data URL
        base64_image_url = f"data:image/jpeg;base64,{image_base64}"

        # Build student list for prompt
        if student_roster:
            student_list = "\n".join([f"- {s['name']} (login: {s['login_id']})" for s in student_roster])
            name_matching_instructions = f"""

STUDENT NAME MATCHING:
The following is a list of students enrolled in this course:
{student_list}

When extracting the student's name from the handwriting:
1. Store the exact name as written in the "name" field (what you read from the handwriting)
2. ONLY if you are HIGHLY CONFIDENT (>90% sure) about a match, store the matched student's name in "matched_name" and their "login_id"
3. If the match confidence is low, the handwriting is unclear, or no clear match exists, set both "matched_name" and "login_id" to null
4. DO NOT make guesses - it's better to have no match than a false positive
5. Common reasons for high confidence: clear handwriting, exact name match, or minor spelling variation of a roster name
"""
            json_schema_addition = """
"name": "Exact name as written in handwriting",
"matched_name": "Roster name if >90% confident match, otherwise null",
"login_id": "Login ID if >90% confident match, otherwise null",
"""
        else:
            name_matching_instructions = ""
            json_schema_addition = """
"name": "Student Name",
"""

        # Modified prompt for image-based grading
        prompt = f"""The student's handwritten response to the quiz question is contained in the attached image. Please read the handwritten text carefully and grade it according to the following instructions:

{grading_instructions}
{name_matching_instructions}

IMPORTANT INSTRUCTIONS:
1. Carefully read and transcribe the student's handwritten response from the image
2. Include the full transcribed text in the "answer_text" field of your JSON response
3. Grade each of the five parts according to the rubric (20 points each)
4. Each question should be either 0 points - for completely incorrect, 10 points - for partially correct, and 20 points - for fully correct and great answer No values outside of 0,10,20.
5. Provide detailed, constructive feedback for each question and why it was either completely incorrect, partially correct or fully correct.
6. Calculate the total score
7. Provide overall feedback summarizing strengths and areas for improvement

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
                        },
                        {
                            "type": "input_image",
                            "image_url": base64_image_url
                        }
                    ]
                }
            ]
        )

        # Calculate elapsed time
        elapsed_time = time.time() - start_time
        print(f"✓ Grading completed in {elapsed_time:.2f} seconds")

        # Try to parse the response as JSON
        try:
            json_response = json.loads(response.output_text)

            # Add grading time to the response
            json_response['grading_time_seconds'] = round(elapsed_time, 2)

            # Save to file immediately after successful parsing
            with open(output_file, 'w') as f:
                json.dump(json_response, f, indent=2)
            print(f"✓ Grading results saved to: {output_file}")

            # Pretty print the JSON
            print("\n" + "="*50)
            print("Grading Results (Fresh):")
            print("="*50)
            print(json.dumps(json_response, indent=2))

            if 'total_score' in json_response:
                print(f"\nTotal Score: {json_response['total_score']}/100")
                print(f"Grading Time: {elapsed_time:.2f} seconds")

        except json.JSONDecodeError:
            # If response isn't valid JSON, print raw response
            print("\n" + "="*50)
            print("Raw Response (couldn't parse as JSON):")
            print("="*50)
            print(response.output_text)
            print("\nWarning: Could not parse response as JSON. No cache file created.")

    except FileNotFoundError:
        print(f"Error: File '{heic_file}' not found.")
        sys.exit(1)
    except AttributeError as e:
        print(f"Error: The GPT-5 API might not be available yet. {e}")
        print("This appears to be a preview/beta API that may require special access.")
        sys.exit(1)
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
