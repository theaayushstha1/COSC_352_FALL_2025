# Dockerfile
FROM haskell:9-slim

RUN mkdir /app
COPY Main.hs /app/Main.hs
COPY baltimore_homicides_combined.csv /app/baltimore_homicides_combined.csv
WORKDIR /app

RUN ghc Main.hs -o analysis

CMD ["./analysis"]