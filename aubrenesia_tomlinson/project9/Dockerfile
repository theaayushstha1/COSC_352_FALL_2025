FROM ubuntu:22.04

RUN apt-get update && apt-get install -y \
    wget \
    curl \
    python3 \
    python3-pip \
    python3-venv \
    git \
    build-essential \
    unzip \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt /tmp/requirements.txt
RUN pip3 install --no-cache-dir -r /tmp/requirements.txt


RUN curl -L "https://get.modular.com/mojo" -o mojo.zip && \
    unzip mojo.zip -d /opt/mojo && \
    rm mojo.zip


ENV PATH="/opt/mojo/bin:${PATH}"

WORKDIR /app
COPY extract.py .
COPY pdfsearch.mojo .
COPY morgan_2030.pdf .

CMD ["bash", "-c", "python3 extract.py morgan_2030.pdf > pages.json && mojo pdfsearch.mojo pages.json 'gradient descent optimization' 3"]
