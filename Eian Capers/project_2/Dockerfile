FROM python:3.11-slim

WORKDIR /app


COPY Project_2.py .
COPY requirement.txt .


RUN pip install --no-cache-dir -r requirement.txt


CMD ["python", "Project_2.py"]