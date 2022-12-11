Compiler workshop - codegen
===========================
* Goal of the exercises is to pass the two tests in testCodeGen.bal
* Definition of the intermediate language is in `modules/ir/ir.bal`
* Use `bal test` command to run the tests
* First one is currently passing but the answer is hardcoded in main.bal codegen function
* Delete the function body and add your own code

Assume
* Given a language where all variables are ints (64 signed ints)
* All functions return an int


Bonus
* Ones both tests are passing you can use `mod.printModuleToFile()` to create an ll file
* Then you can run it using `lli` or compile it to machine code using `llc` or `clang`
* Hint: you will need to add a main function and a way to print sample can be found print_signed_int.ll


Bonus 2
* a test case for Euclid's algorithm
