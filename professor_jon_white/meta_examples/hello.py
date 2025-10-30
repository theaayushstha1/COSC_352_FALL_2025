from functools import wraps

def world_wrapper(func):
    @wraps(func)
    def wrapper(*args, **kwargs):
        print("Are you there world?", 1)
        print("Are you there world?", 2)
        print("Are you there world?", 3.5)
        result = func(*args, **kwargs)
        print("Goodbye world")
        return result
    return wrapper


#@world_wrapper
def hello_world():
    print("Hello world! I'm here")

hello_world()