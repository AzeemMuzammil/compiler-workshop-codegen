import ballerina/test;
import codegen.llvm;
import codegen.ir;


// def add(a, b):
//     return a + b
@test:Config {}
function testCodeGenAdd() returns error? {
    ir:Function add = {
        name: "add",
        params: ["%a", "%b"],
        vars: ["%result"],
        blocks: { "entry": {
                      insns: [
                          { kind: "add", op: ["%a", "%b"], result: "%result" },
                          { kind: "return", op: ["%result"] } ] } } };
    llvm:Module mod = codeGen([add]);
    string expected = string`define i64 @add(i64 %0, i64 %1) {
  %3 = alloca i64
  store i64 %0, i64* %3
  %4 = alloca i64
  store i64 %1, i64* %4
  %5 = alloca i64
  %6 = load i64, i64* %3
  %7 = load i64, i64* %4
  %8 = add i64 %6, %7
  store i64 %8, i64* %5
  %9 = load i64, i64* %5
  ret i64 %9
}`;
    // check mod.printModuleToFile("add.ll");
    test:assertEquals(mod.printModuleToString(), expected);
}


// def fib(n):
//     if n < 2:
//         return n
//     else:
//         return fib(n - 1) + fib(n - 2)
@test:Config {}
function testCodeGenFib() returns error? {
    ir:Function fib = {
        name: "fib",
        params: ["%n"],
        vars: ["%lessThan2", "%nSub1", "%nSub2", "%fib1", "%fib2", "%result"],
        blocks: { "entry": {
                      insns: [
                          { kind: "lessThan", op: ["%n", 2], result: "%lessThan2" },
                          { kind: "jumpIf", op:["%lessThan2"], ifTrue: "trivial", ifFalse: "recursive" } ] },
                  "trivial": {
                      insns: [
                          { kind: "return", op: ["%n"] } ] },
                  "recursive": {
                      insns: [
                          { kind: "subtract", op: ["%n", 1], result: "%nSub1" },
                          { kind: "subtract", op: ["%n", 2], result: "%nSub2" },
                          { kind: "call", name:"fib", op: ["%nSub1"], result: "%fib1" },
                          { kind: "call", name:"fib", op: ["%nSub2"], result: "%fib2" },
                          { kind: "add", op: ["%fib1", "%fib2"], result: "%result" },
                          { kind: "return", op: ["%result"] } ] } } };
    llvm:Module mod = codeGen([fib]);
    string expected = string`define i64 @fib(i64 %0) {
  %2 = alloca i64
  store i64 %0, i64* %2
  %3 = alloca i64
  %4 = alloca i64
  %5 = alloca i64
  %6 = alloca i64
  %7 = alloca i64
  %8 = alloca i64
  %9 = load i64, i64* %2
  %10 = icmp sle i64 %9, 2
  %11 = zext i1 %10 to i64
  store i64 %11, i64* %3
  %12 = load i64, i64* %3
  %13 = trunc i64 %12 to i1
  br i1 %13, label %trivial, label %recursive
trivial:
  %14 = load i64, i64* %2
  ret i64 %14
recursive:
  %15 = load i64, i64* %2
  %16 = sub i64 %15, 1
  store i64 %16, i64* %4
  %17 = load i64, i64* %2
  %18 = sub i64 %17, 2
  store i64 %18, i64* %5
  %19 = load i64, i64* %4
  %20 = call i64 @fib(i64 %19)
  store i64 %20, i64* %6
  %21 = load i64, i64* %5
  %22 = call i64 @fib(i64 %21)
  store i64 %22, i64* %7
  %23 = load i64, i64* %6
  %24 = load i64, i64* %7
  %25 = add i64 %23, %24
  store i64 %25, i64* %8
  %26 = load i64, i64* %8
  ret i64 %26
}`;
    // check mod.printModuleToFile("fib.ll");
    test:assertEquals(mod.printModuleToString(), expected);
}
