FROM haskell:9.6

WORKDIR /app
COPY . .

RUN stack setup
RUN stack build

CMD ["stack", "exec", "homicide-analysis"]
