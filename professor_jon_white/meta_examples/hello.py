#1) What is the following functools library and why is it significant?
from functools import wraps

#2) Explain what this saymore function does and why it's important?
def saymore(func):
    @wraps(func)
    def wrapper(*args, **kwargs):
        print("Are you there world?")
        result = func(*args, **kwargs)
        print("Goodbye world")
        return result
    return wrapper

#3) What is happening in the runtime in the function below
@saymore
def hello_world():
    print("Hello world!")

#4) What is the output of the following code going to be?
print("Hello World")