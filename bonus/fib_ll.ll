define i64 @main() {
entry:
  %res = call i64 @fib(i64 40)
  call void @printSignedInt(i64 %res)
  ret i64 0
}

define i64 @fib(i64 %0) {
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
