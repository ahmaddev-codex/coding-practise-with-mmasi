public class Bank {

    public static void main(String[] args) { // behaviour of the class
        Bank uba = new Bank(); // creating an object of the class Bank, uba is an instance of the class Bank
        Bank gtb = new Bank();

        uba.deposit(25000);
        gtb.deposit(17000);

        uba.withdraw(6000);
        gtb.withdraw(6500);

        uba.checkBalance();
        gtb.checkBalance();

        uba.withdraw(20000);

    }
    
    int balance = 0; // attribute or property or state of the class

    // public Bank(){
    //     System.out.println("Your balance is 0");
    // }

    void deposit(int amount){ // method or function or behaviour
        balance += amount;

        System.out.println("\nYour balance is now: " + balance + " naira\n");
    }

    void withdraw(int amount) {
        if (amount > balance){
            System.out.println("Insufficient fund");
        } else {
            balance -= amount; // balance = balance - amount
        }

        System.out.println("\nYour balance is now: " + balance + " naira\n");
    }

    void checkBalance() {
        System.out.println("\nBalance: " + balance + " naira\n");
    }
}
