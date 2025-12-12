FROM clojure:latest
WORKDIR /app
COPY Main.clj .
COPY baltimore_homicides_combined.csv .
CMD ["clojure", "Main.clj", "baltimore_homicides_combined.csv"]
