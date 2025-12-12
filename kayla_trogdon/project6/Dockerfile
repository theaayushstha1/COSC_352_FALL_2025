FROM golang:1.21
#Using Go base image instead of OpenJDK

WORKDIR /app

COPY go.mod .

#Copy Go source code
COPY *.go . 
COPY chamspage_table1.csv . 

#Builds the Go program
RUN go build -o homicide_analysis . 

#Run it
CMD ["./homicide_analysis"]