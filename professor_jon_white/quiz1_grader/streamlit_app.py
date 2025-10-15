#!/usr/bin/env python3
"""
Streamlit application to display quiz grading results.
Shows student responses, extracted text, and detailed feedback.

Usage:
  streamlit run streamlit_app.py
"""

import streamlit as st
import json
from pathlib import Path
import pandas as pd
from PIL import Image


def find_json_files(data_dir='data'):
    """Find all JSON files in the data directory."""
    data_path = Path(data_dir)
    if not data_path.exists():
        return []
    return sorted(data_path.glob('*.json'))


def read_grading_json(json_file):
    """Read and parse a grading JSON file."""
    try:
        with open(json_file, 'r') as f:
            return json.load(f)
    except Exception as e:
        st.error(f"Error reading {json_file}: {e}")
        return None


def find_png_for_json(json_file):
    """Find the corresponding PNG file for a JSON file."""
    png_file = json_file.with_suffix('.png')
    if png_file.exists():
        return png_file
    return None


@st.cache_data
def load_and_cache_image(image_path):
    """Load and cache an image to avoid reloading."""
    try:
        img = Image.open(str(image_path))
        return img
    except Exception as e:
        return None


def read_grading_instructions(instructions_file='grading_instructions.md'):
    """Read the grading instructions from the markdown file."""
    import os
    script_dir = os.path.dirname(os.path.abspath(__file__))
    instructions_path = os.path.join(script_dir, instructions_file)

    try:
        with open(instructions_path, 'r') as f:
            return f.read()
    except Exception as e:
        return f"Error reading grading instructions: {e}"


def create_feedback_table(scores):
    """Create a DataFrame from the scores dictionary."""
    rows = []
    for i in range(1, 6):
        question_key = f'question_{i}'
        if question_key in scores:
            rows.append({
                'Question': f'Question {i}',
                'Score': f"{scores[question_key].get('score', 0)}/20",
                'Feedback': scores[question_key].get('feedback', 'No feedback')
            })
    return pd.DataFrame(rows)


def main():
    st.set_page_config(
        page_title="Quiz Grading Results",
        page_icon="📝",
        layout="wide"
    )

    # Curve configuration
    CURVE_POINTS = 35  # Add 35 points to all scores

    st.title("📝 Quiz 1 Grading Results")
    st.markdown("### Organization of Programming Languages - Turing Machines")
    st.markdown(f"**Curve Applied:** +{CURVE_POINTS} points to all scores")

    # Find all JSON files
    json_files = find_json_files('data')

    if not json_files:
        st.error("No grading results found in the data directory.")
        return

    # Calculate overall statistics (original and curved)
    all_scores = []
    all_curved_scores = []
    student_data_list = []

    for json_file in json_files:
        data = read_grading_json(json_file)
        if data:
            original_score = data.get('total_score', 0)
            curved_score = min(100, original_score + CURVE_POINTS)  # Cap at 100
            all_scores.append(original_score)
            all_curved_scores.append(curved_score)
            student_data_list.append({
                'json_file': json_file,
                'data': data,
                'total_score': original_score,
                'curved_score': curved_score
            })

    # Sort by curved_score in descending order (highest scores first)
    student_data_list.sort(key=lambda x: x['curved_score'], reverse=True)

    # Create tabs
    tab1, tab2, tab3 = st.tabs(["📊 Overview", "👥 Student Results", "📋 Grading Instructions"])

    # Tab 1: Overview
    with tab1:
        st.markdown("## Grade Statistics")

        if all_scores:
            col1, col2, col3, col4 = st.columns(4)
            with col1:
                st.metric("Total Students", len(all_scores))
            with col2:
                st.metric(
                    "Average Score (Curved)",
                    f"{sum(all_curved_scores)/len(all_curved_scores):.1f}/100",
                    delta=f"+{(sum(all_curved_scores)/len(all_curved_scores)) - (sum(all_scores)/len(all_scores)):.1f}"
                )
            with col3:
                st.metric(
                    "Highest Score (Curved)",
                    f"{max(all_curved_scores)}/100",
                    delta=f"Was {max(all_scores)}"
                )
            with col4:
                st.metric(
                    "Lowest Score (Curved)",
                    f"{min(all_curved_scores)}/100",
                    delta=f"Was {min(all_scores)}"
                )

            st.markdown("---")

            # Per-question statistics
            st.markdown("### Per-Question Averages")
            question_avgs = []
            for i in range(1, 6):
                q_scores = []
                for student_info in student_data_list:
                    data = student_info['data']
                    scores = data.get('scores', {})
                    q_key = f'question_{i}'
                    if q_key in scores:
                        q_scores.append(scores[q_key].get('score', 0))
                if q_scores:
                    avg = sum(q_scores) / len(q_scores)
                    question_avgs.append({'Question': f'Q{i}', 'Average Score': avg})

            if question_avgs:
                q_df = pd.DataFrame(question_avgs)
                st.dataframe(q_df)
                st.bar_chart(q_df.set_index('Question')['Average Score'], height=300)

            st.markdown("---")

            # Grade distribution
            st.markdown("### Grade Distribution")
            grade_ranges = {
                'A (90-100)': sum(1 for s in all_curved_scores if s >= 90),
                'B (80-89)': sum(1 for s in all_curved_scores if 80 <= s < 90),
                'C (70-79)': sum(1 for s in all_curved_scores if 70 <= s < 80),
                'D (60-69)': sum(1 for s in all_curved_scores if 60 <= s < 70),
                'F (0-59)': sum(1 for s in all_curved_scores if s < 60)
            }
            dist_df = pd.DataFrame(list(grade_ranges.items()), columns=['Grade', 'Count'])
            st.dataframe(dist_df)
            st.bar_chart(dist_df.set_index('Grade')['Count'], height=300)

    # Tab 2: Student Results
    with tab2:
        st.markdown("## Individual Student Results")
        st.markdown(f"Showing {len(student_data_list)} students sorted by curved score (highest first)")

        # Create expander for each student (now in curved score order)
        for student_info in student_data_list:
            json_file = student_info['json_file']
            data = student_info['data']
            curved_score = student_info['curved_score']

            student_name = data.get('name', 'Unknown Student')
            matched_name = data.get('matched_name')
            login_id = data.get('login_id')
            total_score = data.get('total_score', 0)
            overall_feedback = data.get('overall_feedback', '')
            answer_text = data.get('answer_text', '')
            scores = data.get('scores', {})
            grading_time = data.get('grading_time_seconds', 'N/A')

            # Determine display name for expander
            display_name = matched_name if matched_name else student_name

            # Determine color based on curved score
            if curved_score >= 90:
                score_color = "🟢"
            elif curved_score >= 80:
                score_color = "🟡"
            elif curved_score >= 70:
                score_color = "🟠"
            else:
                score_color = "🔴"

            # Create expander for this student
            with st.expander(f"{score_color} **{display_name}** - {curved_score}/100 (Curved)", expanded=False):

                # Top section: Student info
                if matched_name:
                    st.markdown(f"### {matched_name}")
                    if login_id:
                        st.caption(f"📝 Handwritten name: *{student_name}* | 🆔 Login: `{login_id}`")
                    else:
                        st.caption(f"📝 Handwritten name: *{student_name}*")
                else:
                    st.markdown(f"### {student_name}")
                    st.caption("⚠️ No confident roster match found")

                score_col1, score_col2, score_col3, score_col4 = st.columns([2, 2, 2, 4])
                with score_col1:
                    st.metric("Original Score", f"{total_score}/100")
                with score_col2:
                    st.metric("Curved Score", f"{curved_score}/100", delta=f"+{curved_score - total_score}")
                with score_col3:
                    st.metric("Grading Time", f"{grading_time}s" if grading_time != 'N/A' else 'N/A')
                with score_col4:
                    st.markdown("**Overall Feedback:**")
                    st.info(overall_feedback)

                st.markdown("---")

                # Middle section: Image and extracted text side by side
                st.markdown("#### 📸 Original Response & Extracted Text")

                col_img, col_text = st.columns([1, 1])

                with col_img:
                    st.markdown("**Original Quiz Photo:**")
                    png_file = find_png_for_json(json_file)
                    if png_file:
                        img = load_and_cache_image(png_file)
                        if img:
                            st.image(img, use_column_width=True)
                        else:
                            st.error("Could not load image")
                    else:
                        st.warning("PNG file not found")

                with col_text:
                    st.markdown("**Extracted Answer Text:**")
                    st.text_area(
                        "Student's Response",
                        answer_text,
                        height=400,
                        disabled=True,
                        label_visibility="collapsed"
                    )

                st.markdown("---")

                # Bottom section: Feedback table
                st.markdown("#### 📊 Detailed Question Feedback")

                feedback_df = create_feedback_table(scores)

                # Display as a nice table spanning full width
                st.table(feedback_df.set_index('Question'))

    # Tab 3: Grading Instructions
    with tab3:
        st.markdown("## Grading Instructions & Rubric")

        # Read and display the grading instructions
        instructions = read_grading_instructions()
        st.markdown(instructions)


if __name__ == "__main__":
    main()
