#!/usr/bin/env python3
"""
Script to consolidate all grading JSON files into a single CSV report.
Reads all .json files from the data directory and creates a comprehensive grade report.

Usage:
  python create_grade_report.py
  python create_grade_report.py --output custom_report.csv
"""

import json
import csv
import os
import sys
from pathlib import Path


def find_json_files(data_dir='data'):
    """Find all JSON files in the data directory."""
    json_files = []
    data_path = Path(data_dir)

    if not data_path.exists():
        print(f"Error: Directory '{data_dir}' not found.")
        return json_files

    # Find all .json files (but exclude any that might be logs or other non-grading files)
    for json_file in data_path.glob('*.json'):
        json_files.append(json_file)

    return sorted(json_files)


def read_grading_json(json_file):
    """Read and parse a grading JSON file."""
    try:
        with open(json_file, 'r') as f:
            data = json.load(f)
        return data
    except json.JSONDecodeError as e:
        print(f"Warning: Could not parse {json_file}: {e}")
        return None
    except Exception as e:
        print(f"Warning: Could not read {json_file}: {e}")
        return None


def create_csv_report(json_files, output_file='grade_report.csv'):
    """Create a CSV report from all grading JSON files."""

    if not json_files:
        print("No JSON files to process.")
        return

    # Curve configuration
    CURVE_POINTS = 35  # Add 35 points to all scores

    # CSV column headers
    fieldnames = [
        'name',
        'matched_name',
        'login_id',
        'answer_text',
        'question_1_score',
        'question_1_feedback',
        'question_2_score',
        'question_2_feedback',
        'question_3_score',
        'question_3_feedback',
        'question_4_score',
        'question_4_feedback',
        'question_5_score',
        'question_5_feedback',
        'total_score',
        'curved_score',
        'overall_feedback',
        'grading_time_seconds',
        'source_file'
    ]

    rows = []

    # Process each JSON file
    for json_file in json_files:
        print(f"Processing: {json_file.name}")
        data = read_grading_json(json_file)

        if data is None:
            continue

        # Build row for this student
        total_score = data.get('total_score', 0)
        curved_score = min(100, total_score + CURVE_POINTS)  # Cap at 100

        # Get matched name, or use original name if no confident match
        matched_name = data.get('matched_name')
        if not matched_name:
            matched_name = ''  # Leave blank if no confident match

        row = {
            'name': data.get('name', 'Unknown'),
            'matched_name': matched_name,
            'login_id': data.get('login_id', ''),
            'answer_text': data.get('answer_text', ''),
            'total_score': total_score,
            'curved_score': curved_score,
            'overall_feedback': data.get('overall_feedback', ''),
            'grading_time_seconds': data.get('grading_time_seconds', ''),
            'source_file': json_file.name
        }

        # Extract scores and feedback for each question
        scores = data.get('scores', {})
        for i in range(1, 6):
            question_key = f'question_{i}'
            if question_key in scores:
                row[f'question_{i}_score'] = scores[question_key].get('score', 0)
                row[f'question_{i}_feedback'] = scores[question_key].get('feedback', '')
            else:
                row[f'question_{i}_score'] = 0
                row[f'question_{i}_feedback'] = 'Missing'

        rows.append(row)

    # Write to CSV
    try:
        with open(output_file, 'w', newline='', encoding='utf-8') as csvfile:
            writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
            writer.writeheader()
            writer.writerows(rows)

        print(f"\n✓ CSV report created: {output_file}")
        print(f"Total students: {len(rows)}")
        print(f"Curve applied: +{CURVE_POINTS} points")

        # Calculate and display summary statistics
        if rows:
            total_scores = [row['total_score'] for row in rows]
            curved_scores = [row['curved_score'] for row in rows]
            avg_score = sum(total_scores) / len(total_scores)
            avg_curved = sum(curved_scores) / len(curved_scores)
            min_score = min(total_scores)
            max_score = max(total_scores)
            min_curved = min(curved_scores)
            max_curved = max(curved_scores)

            print(f"\nGrade Summary (Original):")
            print(f"  Average Score: {avg_score:.2f}/100")
            print(f"  Highest Score: {max_score}/100")
            print(f"  Lowest Score: {min_score}/100")

            print(f"\nGrade Summary (Curved):")
            print(f"  Average Score: {avg_curved:.2f}/100 (+{avg_curved - avg_score:.2f})")
            print(f"  Highest Score: {max_curved}/100")
            print(f"  Lowest Score: {min_curved}/100")

            # Calculate per-question averages
            print(f"\nPer-Question Averages:")
            for i in range(1, 6):
                question_scores = [row[f'question_{i}_score'] for row in rows if f'question_{i}_score' in row]
                if question_scores:
                    avg_q_score = sum(question_scores) / len(question_scores)
                    print(f"  Question {i}: {avg_q_score:.2f}/20")

            # Print all students and their grades
            print("\n" + "="*88)
            print("ALL STUDENT GRADES")
            print("="*88)
            print(f"{'Student Name':<30} {'Q1':>4} {'Q2':>4} {'Q3':>4} {'Q4':>4} {'Q5':>4} {'Total':>6} {'Curved':>7}")
            print("-"*88)

            # Sort by curved score (descending) for display
            sorted_rows = sorted(rows, key=lambda x: x['curved_score'], reverse=True)

            for row in sorted_rows:
                name = row['name'][:28]  # Truncate long names
                q1 = row.get('question_1_score', 0)
                q2 = row.get('question_2_score', 0)
                q3 = row.get('question_3_score', 0)
                q4 = row.get('question_4_score', 0)
                q5 = row.get('question_5_score', 0)
                total = row['total_score']
                curved = row['curved_score']

                print(f"{name:<30} {q1:>4} {q2:>4} {q3:>4} {q4:>4} {q5:>4} {total:>6} {curved:>7}")

            # Calculate and print averages at the bottom
            print("-"*88)
            avg_q1 = sum(row.get('question_1_score', 0) for row in rows) / len(rows)
            avg_q2 = sum(row.get('question_2_score', 0) for row in rows) / len(rows)
            avg_q3 = sum(row.get('question_3_score', 0) for row in rows) / len(rows)
            avg_q4 = sum(row.get('question_4_score', 0) for row in rows) / len(rows)
            avg_q5 = sum(row.get('question_5_score', 0) for row in rows) / len(rows)
            avg_total = sum(row['total_score'] for row in rows) / len(rows)
            avg_curved = sum(row['curved_score'] for row in rows) / len(rows)

            print(f"{'AVERAGE':<30} {avg_q1:>4.1f} {avg_q2:>4.1f} {avg_q3:>4.1f} {avg_q4:>4.1f} {avg_q5:>4.1f} {avg_total:>6.1f} {avg_curved:>7.1f}")
            print("="*88)

    except Exception as e:
        print(f"Error writing CSV file: {e}")
        sys.exit(1)


def main():
    # Parse command line arguments
    output_file = 'grade_report.csv'

    if '--output' in sys.argv:
        idx = sys.argv.index('--output')
        if idx + 1 < len(sys.argv):
            output_file = sys.argv[idx + 1]

    # Find all JSON files
    print("Searching for grading JSON files in data directory...")
    json_files = find_json_files('data')

    if not json_files:
        print("No JSON files found in data directory.")
        sys.exit(0)

    print(f"Found {len(json_files)} JSON files to process\n")

    # Create CSV report
    create_csv_report(json_files, output_file)


if __name__ == "__main__":
    main()
