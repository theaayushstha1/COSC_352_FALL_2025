FROM python:3.11-slim

WORKDIR /app


COPY Project_3.py .
COPY requirement.txt .


RUN pip install --no-cache-dir -r requirement.txt


CMD ["python", "Project_3.py"]