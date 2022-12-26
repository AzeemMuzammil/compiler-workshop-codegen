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
  %10 = icmp slt i64 %9, 2
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

// function findMod(int a, int b) returns int {
//     if a < b {
//         return a;
//     } else {
//         int fa = a - b;
//         if (fa < b) {
//             return fa;
//         } else {
//             return findMod(fa, b);
//         }
//     }
// }

// function gcd(int a, int b) returns int {
//     if b == 0 {
//         return a;
//     } else {
//         return gcd(b, findMod(a, b));
//     }
// }
@test:Config {}
function testCodeGenEuclid() returns error? {
  ir:Function findMod = {
        name: "findMod",
        params: ["%a", "%b"],
        vars: ["%aLessThanB", "%aSubB", "%aSubBLessThanB", "%recRes"],
        blocks: { "entry": {
                      insns: [
                          { kind: "lessThan", op: ["%a", "%b"], result: "%aLessThanB" },
                          { kind: "jumpIf", op:["%aLessThanB"], ifTrue: "trivial", ifFalse: "subOp" } ] },
                  "trivial": {
                      insns: [
                          { kind: "return", op: ["%a"] } ] },
                  "subOp": {
                      insns: [
                          { kind: "subtract", op: ["%a", "%b"], result: "%aSubB" },
                          { kind: "lessThan", op: ["%aSubB", "%b"], result: "%aSubBLessThanB" },
                          { kind: "jumpIf", op:["%aSubBLessThanB"], ifTrue: "trivialAfterSubOp", ifFalse: "recursive" } ] },
                  "trivialAfterSubOp": {
                      insns: [
                          { kind: "return", op: ["%aSubB"] } ] },
                  "recursive": {
                      insns: [
                          { kind: "call", name:"findMod", op: ["%aSubB", "%b"], result: "%recRes" },
                          { kind: "return", op: ["%recRes"] } ] } } };
  ir:Function gcd = {
        name: "gcd",
        params: ["%a", "%b"],
        vars: ["%bLessThan0", "%bGreaterThan0", "%aLessThanB", "%aModB", "%gcdRes"],
        blocks: { "entry": {
                      insns: [
                          { kind: "lessThan", op: ["%b", 0], result: "%bLessThan0" },
                          { kind: "jumpIf", op:["%bLessThan0"], ifTrue: "recursive", ifFalse: "checkForGreater" } ] },
                  "checkForGreater": {
                      insns: [
                          { kind: "lessThan", op: [0, "%b"], result: "%bGreaterThan0" },
                          { kind: "jumpIf", op:["%bGreaterThan0"], ifTrue: "recursive", ifFalse: "trivial" } ] },
                  "trivial": {
                      insns: [
                          { kind: "return", op: ["%a"] } ] },
                  "recursive": {
                      insns: [
                          { kind: "call", name:"findMod", op: ["%a", "%b"], result: "%aModB" },
                          { kind: "call", name:"gcd", op: ["%b", "%aModB"], result: "%gcdRes" },
                          { kind: "return", op: ["%gcdRes"] } ] } } };
  llvm:Module mod = codeGen([findMod, gcd]);
  string expected = string`define i64 @findMod(i64 %0, i64 %1) {
  %3 = alloca i64
  store i64 %0, i64* %3
  %4 = alloca i64
  store i64 %1, i64* %4
  %5 = alloca i64
  %6 = alloca i64
  %7 = alloca i64
  %8 = alloca i64
  %9 = load i64, i64* %3
  %10 = load i64, i64* %4
  %11 = icmp slt i64 %9, %10
  %12 = zext i1 %11 to i64
  store i64 %12, i64* %5
  %13 = load i64, i64* %5
  %14 = trunc i64 %13 to i1
  br i1 %14, label %trivial, label %subOp
trivial:
  %15 = load i64, i64* %3
  ret i64 %15
subOp:
  %16 = load i64, i64* %3
  %17 = load i64, i64* %4
  %18 = sub i64 %16, %17
  store i64 %18, i64* %6
  %19 = load i64, i64* %6
  %20 = load i64, i64* %4
  %21 = icmp slt i64 %19, %20
  %22 = zext i1 %21 to i64
  store i64 %22, i64* %7
  %23 = load i64, i64* %7
  %24 = trunc i64 %23 to i1
  br i1 %24, label %trivialAfterSubOp, label %recursive
trivialAfterSubOp:
  %25 = load i64, i64* %6
  ret i64 %25
recursive:
  %26 = load i64, i64* %6
  %27 = load i64, i64* %4
  %28 = call i64 @findMod(i64 %26, i64 %27)
  store i64 %28, i64* %8
  %29 = load i64, i64* %8
  ret i64 %29
}
define i64 @gcd(i64 %0, i64 %1) {
  %3 = alloca i64
  store i64 %0, i64* %3
  %4 = alloca i64
  store i64 %1, i64* %4
  %5 = alloca i64
  %6 = alloca i64
  %7 = alloca i64
  %8 = alloca i64
  %9 = alloca i64
  %10 = load i64, i64* %4
  %11 = icmp slt i64 %10, 0
  %12 = zext i1 %11 to i64
  store i64 %12, i64* %5
  %13 = load i64, i64* %5
  %14 = trunc i64 %13 to i1
  br i1 %14, label %recursive, label %checkForGreater
checkForGreater:
  %15 = load i64, i64* %4
  %16 = icmp slt i64 0, %15
  %17 = zext i1 %16 to i64
  store i64 %17, i64* %6
  %18 = load i64, i64* %6
  %19 = trunc i64 %18 to i1
  br i1 %19, label %recursive, label %trivial
trivial:
  %20 = load i64, i64* %3
  ret i64 %20
recursive:
  %21 = load i64, i64* %3
  %22 = load i64, i64* %4
  %23 = call i64 @findMod(i64 %21, i64 %22)
  store i64 %23, i64* %8
  %24 = load i64, i64* %4
  %25 = load i64, i64* %8
  %26 = call i64 @gcd(i64 %24, i64 %25)
  store i64 %26, i64* %9
  %27 = load i64, i64* %9
  ret i64 %27
}`;
  test:assertEquals(mod.printModuleToString(), expected);
}
