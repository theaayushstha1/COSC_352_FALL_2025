FROM haskell:9.4

WORKDIR /app

COPY baltimore-homicides.cabal ./
COPY src ./src
COPY app ./app
COPY baltimore_homicides_combined.csv ./baltimore_homicides_combined.csv

RUN cabal update
RUN cabal build

CMD ["cabal", "run", "baltimore-homicides"]
