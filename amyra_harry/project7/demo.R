example <- 123

example_data <- data.frame(
    ID = 1:10,
    Age = sample(18:50, 10, replace = TRUE),
    Score = round(runif(10, 50, 100), 1)

)

print(example_data)

hist(example_data$Age,
min = "Histogran of Age",
xlab = "Age",
ylab = "Frequency",
cal = " lightblue",
border = "black"
)

