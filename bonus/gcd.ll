define i64 @main() {
entry:
  %res = call i64 @gcd(i64 1235, i64 1765)
  call void @printSignedInt(i64 %res)
  ret i64 0
}

define i64 @findMod(i64 %0, i64 %1) {
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
}

define void @printSignedInt(i64 %signedInt) {
entry:
 %isNeg = icmp slt i64 %signedInt, 0
 br i1 %isNeg, label %printMinus, label %printDigits
printMinus:
  call i32 @putchar(i32 45) ; 45 is the ascii code for '-'
  %positiveInt = sub nsw i64 0, %signedInt
  br label %printDigits
printDigits:
  %absInt = phi i64 [ %positiveInt, %printMinus ], [ %signedInt, %entry ]
  %moreThanOneDigit = icmp sgt i64 %absInt, 9
  br i1 %moreThanOneDigit, label %printTens, label %printOnes
printTens:
  %tens = udiv i64 %absInt, 10
  call void @printSignedInt(i64 %tens)
  br label %printOnes
printOnes:
  %lastDigit = srem i64 %absInt, 10
  %lastDigitAscii = add nsw i64 %lastDigit, 48 ; 48 is the ascii code for '0'
  %lastDigitAscii32 = trunc i64 %lastDigitAscii to i32;
  call i32 @putchar(i32 %lastDigitAscii32)
  ret void
}

declare i32 @putchar(i32)
