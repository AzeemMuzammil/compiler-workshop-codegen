define i64 @main() {
  call void @printSignedInt(i64 424242)
  ret i64 0
}

define void @printSignedInt(i64 %signedInt) {
entry:
  %isPositive = icmp slt i64 %signedInt, 0
  br i1 %isPositive, label %printMinus, label %printDigits
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
