FROM openjdk:8

RUN apt-get update && apt-get install -y scala python3 python3-pip && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY requirements.txt .
RUN pip3 install --no-cache-dir -r requirements.txt

COPY fetch_csv.py .
COPY article_questions.scala . 
COPY chamspage_table1.csv .

RUN scalac article_questions.scala

CMD ["scala", "HomicideAnalysis"] 