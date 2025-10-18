#!/usr/bin/env python3
"""
Script to create a PDF report for a single student's quiz results.
Includes the original image, extracted text, grades, and feedback.

Usage:
  python create_student_pdf.py data/IMG_8863.json
"""

import json
import sys
import os
import hashlib
from pathlib import Path
from reportlab.lib.pagesizes import letter
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import inch
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, Image as RLImage
from reportlab.lib.enums import TA_LEFT, TA_CENTER
from reportlab.lib import colors


def sanitize_filename(filename):
    """Remove invalid characters from filename"""
    invalid_chars = '<>:"/\\|?*'
    for char in invalid_chars:
        filename = filename.replace(char, '_')
    return filename[:100]


def get_styles():
    """Get consistent styles for PDFs"""
    styles = getSampleStyleSheet()

    styles.add(ParagraphStyle(
        name='StudentTitle',
        parent=styles['Title'],
        fontSize=20,
        textColor=colors.HexColor('#2C3E50'),
        spaceAfter=12,
        alignment=TA_CENTER,
        leading=24
    ))

    styles.add(ParagraphStyle(
        name='SectionTitle',
        parent=styles['Heading2'],
        fontSize=13,
        textColor=colors.HexColor('#34495E'),
        spaceAfter=8,
        spaceBefore=12,
        leading=16
    ))

    styles.add(ParagraphStyle(
        name='QuizBodyText',
        parent=styles['Normal'],
        fontSize=9,
        leading=11,
        alignment=TA_LEFT
    ))

    styles.add(ParagraphStyle(
        name='QuizSmallText',
        parent=styles['Normal'],
        fontSize=8,
        leading=10,
        textColor=colors.HexColor('#666666')
    ))

    styles.add(ParagraphStyle(
        name='FeedbackText',
        parent=styles['Normal'],
        fontSize=8,
        leading=10,
        alignment=TA_LEFT,
        splitLongWords=True
    ))

    return styles


def create_student_pdf(json_path, output_dir=None):
    """Create a PDF report for a student"""

    # Read JSON file
    try:
        with open(json_path, 'r') as f:
            data = json.load(f)
    except Exception as e:
        print(f"Error reading JSON file: {e}")
        return False

    # Extract data
    student_name = data.get('name', 'Unknown Student')
    matched_name = data.get('matched_name')
    login_id = data.get('login_id')
    answer_text = data.get('answer_text', '')
    scores = data.get('scores', {})
    total_score = data.get('total_score', 0)
    curved_score = min(100, total_score + 35)  # Apply curve
    overall_feedback = data.get('overall_feedback', '')
    grading_time = data.get('grading_time_seconds', 'N/A')

    # Determine display name
    display_name = matched_name if matched_name else student_name

    # Find PNG file
    json_file = Path(json_path)
    png_path = json_file.with_suffix('.png')

    if not png_path.exists():
        print(f"Warning: PNG file not found: {png_path}")
        png_path = None

    # Determine output path
    # Create lowercase filename with underscores and _quiz1 suffix
    if display_name.lower() in ['unknown student', 'unknown', '']:
        # For unknown students, create unique hash from image filename
        image_hash = hashlib.md5(json_file.stem.encode()).hexdigest()[:8]
        base_name = f"unknown_{image_hash}"
        pdf_filename = f"{base_name}_quiz1.pdf"
    else:
        base_name = display_name.lower().replace(' ', '_')
        base_name = sanitize_filename(base_name)
        pdf_filename = f"{base_name}_quiz1.pdf"

    if not output_dir:
        # Default to 'pdfs' directory
        script_dir = os.path.dirname(os.path.abspath(__file__))
        output_dir = os.path.join(script_dir, 'pdfs')

    os.makedirs(output_dir, exist_ok=True)
    output_path = os.path.join(output_dir, pdf_filename)

    print(f"Creating PDF for {display_name}...")

    # Create PDF
    doc = SimpleDocTemplate(
        output_path,
        pagesize=letter,
        rightMargin=36,
        leftMargin=36,
        topMargin=36,
        bottomMargin=36,
    )

    styles = get_styles()
    elements = []

    # Title
    title_text = f"<b>Quiz 1 Grading Report: {display_name}</b>"
    elements.append(Paragraph(title_text, styles['StudentTitle']))

    # Student info line
    info_parts = []
    if matched_name and matched_name != student_name:
        info_parts.append(f"Handwritten: {student_name}")
    if login_id:
        info_parts.append(f"Login: {login_id}")

    if info_parts:
        elements.append(Paragraph(" | ".join(info_parts), styles['QuizSmallText']))

    elements.append(Spacer(1, 8))

    # Score summary
    score_data = [
        ['Original Score', 'Curved Score (+35)', 'Grading Time'],
        [f'{total_score}/100', f'{curved_score}/100', f'{grading_time}s' if grading_time != 'N/A' else 'N/A']
    ]

    score_table = Table(score_data, colWidths=[2*inch, 2*inch, 1.5*inch])
    score_table.setStyle(TableStyle([
        ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
        ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
        ('FONTSIZE', (0, 0), (-1, -1), 10),
        ('GRID', (0, 0), (-1, -1), 1, colors.grey),
        ('BACKGROUND', (0, 0), (-1, 0), colors.lightgrey),
        ('BACKGROUND', (1, 1), (1, 1), colors.HexColor('#E8F5E9')),
        ('TEXTCOLOR', (1, 1), (1, 1), colors.HexColor('#2E7D32')),
        ('FONTNAME', (1, 1), (1, 1), 'Helvetica-Bold'),
    ]))
    elements.append(score_table)
    elements.append(Spacer(1, 12))

    # Overall feedback
    elements.append(Paragraph("<b>Overall Feedback</b>", styles['SectionTitle']))
    elements.append(Paragraph(overall_feedback, styles['QuizBodyText']))
    elements.append(Spacer(1, 12))

    # Two-column layout for image and extracted text + feedback
    elements.append(Paragraph("<b>Original Response, Extracted Text & Feedback</b>", styles['SectionTitle']))
    elements.append(Spacer(1, 6))

    # Create two-column table
    col_data = []

    # Left column: Image
    left_col_elements = []
    if png_path and png_path.exists():
        try:
            img = RLImage(str(png_path), width=2.8*inch, height=4*inch, kind='proportional')
            left_col_elements.append(img)
        except Exception as e:
            left_col_elements.append(Paragraph(f"[Image error: {str(e)[:30]}]", styles['QuizSmallText']))
    else:
        left_col_elements.append(Paragraph("[Image not found]", styles['QuizSmallText']))

    # Right column: Extracted text + Question feedback
    right_col_elements = []

    # Extracted text section
    right_col_elements.append(Paragraph("<b>Extracted Answer Text:</b>", styles['QuizBodyText']))
    right_col_elements.append(Spacer(1, 4))

    # Truncate text if too long to fit
    display_text = answer_text
    if len(display_text) > 600:
        display_text = display_text[:600] + "..."

    right_col_elements.append(Paragraph(f"<font size=7>{display_text}</font>", styles['QuizBodyText']))
    right_col_elements.append(Spacer(1, 10))

    # Question scores and feedback
    right_col_elements.append(Paragraph("<b>Question Scores & Feedback:</b>", styles['QuizBodyText']))
    right_col_elements.append(Spacer(1, 4))

    for i in range(1, 6):
        q_key = f'question_{i}'
        if q_key in scores:
            q_score = scores[q_key].get('score', 0)
            q_feedback = scores[q_key].get('feedback', 'No feedback')

            # Question header
            question_header = f"<b>Q{i}: {q_score}/20</b>"
            right_col_elements.append(Paragraph(question_header, styles['FeedbackText']))
            right_col_elements.append(Spacer(1, 2))

            # Feedback paragraph
            right_col_elements.append(Paragraph(q_feedback, styles['FeedbackText']))
            right_col_elements.append(Spacer(1, 6))

    # Add to table
    col_data.append([left_col_elements, right_col_elements])

    content_table = Table(col_data, colWidths=[3*inch, 4*inch])
    content_table.setStyle(TableStyle([
        ('VALIGN', (0, 0), (-1, -1), 'TOP'),
        ('LEFTPADDING', (0, 0), (-1, -1), 6),
        ('RIGHTPADDING', (0, 0), (-1, -1), 6),
    ]))
    elements.append(content_table)

    # Build PDF
    try:
        doc.build(elements)
        print(f"✓ Created: {output_path}")
        return output_path
    except Exception as e:
        print(f"✗ Error creating PDF: {e}")
        return None


def main():
    if len(sys.argv) < 2:
        print("Usage: python create_student_pdf.py <student_json_file> [output_dir]")
        sys.exit(1)

    json_path = sys.argv[1]
    output_dir = sys.argv[2] if len(sys.argv) > 2 else None

    if not os.path.exists(json_path):
        print(f"Error: File not found: {json_path}")
        sys.exit(1)

    result = create_student_pdf(json_path, output_dir)
    sys.exit(0 if result else 1)


if __name__ == "__main__":
    main()
