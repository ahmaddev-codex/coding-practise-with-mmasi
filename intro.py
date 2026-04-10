# sequences, selection, iteration

## sequences
print("\nEnter your age in number: ")
age = int(input()) # int is used for type-casting

admission_age = 17

if age >= admission_age:
    print("nYou are qualified for admission\n")
else:
    print("\nYou are not qualified for admission\n")

# escape characters
# \n - new line
# \t - horizontal tab
# \v - vertical tab
# \' - single quote
# \" - double quote
# \\ - backward slash

# ===== FooBar Program ======
for count in range(1,31):
    if count % 3 == 0 and count % 5 == 0:
        print("FoorBar")
    elif count % 3 == 0:
        print("Foo")
    elif count % 5 == 0:
        print("Bar")
    else:
        print(count)


age = 25 # variable
first_name = "Mmasi" # variable
First_Name = "Mmasi" # variable
_pp = 100 # variable
# 0012 = 100 # invalid variable name

# cases for variable names
# 1. variable names must start with a letter or an underscore
# 2. variable names can only contain letters, numbers, and underscores
# 3. variable names cannot be a reserved keyword # if else try finally
# 4. variable names are case-sensitive
# 5. variable names should be descriptive and meaningful

# varaibles cases
# 1. snake_case - first_name, last_name, age
# 2. camelCase - firstName, lastName, age
# 3. PascalCase - FirstName, LastName, Age

# Banking Simulation

balance = 0 # variable

def deposit(amount): # function or method
    balance += amount
    print(f"\nYour balance is now: {balance} naira\n")

# def is used to define a function
# withdraw is the name of the function
# amount is the parameter
def withdraw(amount):
    if amount > balance:
        print("\nInsufficient funds\n")
    else:
        balance -= amount
        print(f"\nYour balance is now: {balance} naira\n")

def check_balance():
    print(f"\nBalance: {balance} naira\n")
