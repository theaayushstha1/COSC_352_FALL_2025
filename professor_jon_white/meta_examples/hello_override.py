import builtins

original_print = builtins.print

def custom_print(*args, **kwargs):
    return args[0] + args[1]

builtins.print = custom_print

val = print(1, 2, "Hello world!")

original_print(val)

