from functools import wraps

#1) Explain how the following code works from a metadata perspective.  
# what does @wraps do and the wrapper function with the returns?
def inches(func):
    @wraps(func)
    def wrapper(*args, **kwargs):
        result = func(*args, **kwargs)
        return result
    return wrapper

def feet(func):
    @wraps(func)
    def wrapper(*args, **kwargs):
        result = func(*args, **kwargs)
        return result * 12
    return wrapper

#2) When the following annotations are applied here what do they do at runtime?
@feet
def a():
    return 5.5 

@inches
def b():
    return 18

#3) Explain the following logic of this function and why it's needed
def run(*values, unit="inches"):
    total_inches = sum(values)
    if unit == "inches":
        return total_inches
    elif unit == "feet":
        return total_inches / 12
    else:
        raise ValueError("Unsupported unit")

#4) Does the following code work and if yes what is the output of the following code?
print(run(a(), b()))
print(run(a(), b(), unit="feet"))

