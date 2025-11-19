values = [1, 2, 3, 4]

# More compact using lambda
answers = list(map(
    lambda idx_val: 
        eval('*'.join(str(values[i]) 
            for i in range(len(values)) if i != idx_val[0])),
                enumerate(values)
))

print(answers)