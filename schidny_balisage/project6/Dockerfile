FROM golang:1.21-alpine

# Install wget for downloading data
RUN apk add --no-cache wget

# Set working directory
WORKDIR /app

# Copy go module files
COPY go.mod ./

# Copy source code
COPY main.go ./

# Download Baltimore crime data
RUN mkdir -p /data && \
    cd /data && \
    wget https://data.baltimorecity.gov/api/views/wsfq-mvij/rows.csv?accessType=DOWNLOAD -O BPD_Part_1_Victim_Based_Crime_Data.csv

# Build the application
RUN go build -o baltimore-analysis main.go

# Set the entrypoint
ENTRYPOINT ["./baltimore-analysis"]
