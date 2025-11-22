FROM haskell:9.4-slim
WORKDIR /app
COPY BaltimoreHomicides.hs .
COPY baltimore_homicides_combined.csv .
RUN ghc -O2 -o baltimore-analysis BaltimoreHomicides.hs
ENTRYPOINT ["./baltimore-analysis"]
CMD ["baltimore_homicides_combined.csv"]
