; RUN: llc -mcpu=core2 -mtriple=i686-pc-win32 -o - -O0 < %s | llvm-mc -triple=i686-pc-win32 -filetype=obj | llvm-readobj -s -sr -codeview -section-symbols | FileCheck %s

; This LL file was generated by running clang on the following code:
; D:\src.cpp:
;  1 namespace foo {
;  2 int bar(int x) {
;  3   return x * 2;
;  4 }
;  5 }

; CHECK:        ProcStart {
; FIXME: The display name should in fact be "foo::bar", see PR21528
; CHECK-NEXT:     DisplayName: ?bar@foo@@YAHH@Z
; CHECK-NEXT:     Section: ?bar@foo@@YAHH@Z

; Function Attrs: nounwind
define i32 @"\01?bar@foo@@YAHH@Z"(i32 %x) #0 {
entry:
  %x.addr = alloca i32, align 4
  store i32 %x, i32* %x.addr, align 4
  %0 = load i32, i32* %x.addr, align 4, !dbg !11
  %mul = mul nsw i32 %0, 2, !dbg !11
  ret i32 %mul, !dbg !11
}

attributes #0 = { nounwind "less-precise-fpmad"="false" "no-frame-pointer-elim"="false" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "no-realign-stack" "stack-protector-buffer-size"="8" "unsafe-fp-math"="false" "use-soft-float"="false" }

!llvm.dbg.cu = !{!0}
!llvm.module.flags = !{!8, !9}
!llvm.ident = !{!10}

!0 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, producer: "clang version 3.6.0 ", isOptimized: false, emissionKind: 2, file: !1, enums: !2, retainedTypes: !2, subprograms: !3, globals: !2, imports: !2)
!1 = !DIFile(filename: "<stdin>", directory: "D:\5C")
!2 = !{}
!3 = !{!4}
!4 = !DISubprogram(name: "bar", line: 2, isLocal: false, isDefinition: true, flags: DIFlagPrototyped, isOptimized: false, scopeLine: 2, file: !5, scope: !6, type: !7, function: i32 (i32)* @"\01?bar@foo@@YAHH@Z", variables: !2)
!5 = !DIFile(filename: "src.cpp", directory: "D:\5C")
!6 = !DIFile(filename: "src.cpp", directory: "D:C")
!7 = !DISubroutineType(types: !2)
!8 = !{i32 2, !"Dwarf Version", i32 4}
!9 = !{i32 2, !"Debug Info Version", i32 3}
!10 = !{!"clang version 3.6.0 "}
!11 = !DILocation(line: 3, scope: !4)
