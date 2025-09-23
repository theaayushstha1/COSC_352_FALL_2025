FROM python:3.11-slim
WORKDIR /app
COPY project2Cod.py .
COPY Requirements.txt .
RUN pip install --no-cache-dir -r Requirements.txt
CMD ["python", "./project2Cod.py"]