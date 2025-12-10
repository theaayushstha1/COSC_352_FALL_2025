FROM haskell:9-slim

RUN mkdir /app
WORKDIR /app

# Install required libraries
RUN cabal update && cabal install cassava vector

COPY Main.hs /app/Main.hs
COPY baltimore_homicides_combined.csv /app/baltimore_homicides_combined.csv

RUN ghc Main.hs -o analysis

CMD ["./analysis"]
