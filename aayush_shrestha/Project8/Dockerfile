FROM haskell:latest

WORKDIR /app

COPY Main.hs /app/
COPY baltimore_homicides_combined.csv /app/

RUN ghc -O2 Main.hs -o analyze

CMD ["./analyze", "baltimore_homicides_combined.csv"]
