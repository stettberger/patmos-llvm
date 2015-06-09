//===- lib/MC/MCSymbol.cpp - MCSymbol implementation ----------------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

#include "llvm/MC/MCSymbol.h"
#include "llvm/MC/MCAsmInfo.h"
#include "llvm/MC/MCContext.h"
#include "llvm/MC/MCExpr.h"
#include "llvm/Support/Debug.h"
#include "llvm/Support/ErrorHandling.h"
#include "llvm/Support/raw_ostream.h"
using namespace llvm;

// Sentinel value for the absolute pseudo section.
MCSection *MCSymbol::AbsolutePseudoSection = reinterpret_cast<MCSection *>(1);

void *MCSymbol::operator new(size_t s, NameEntryTy *Name, MCContext &Ctx) {
  size_t Size = s + (Name ? sizeof(Name) : 0);

  // For safety, ensure that the alignment of a pointer is enough for an
  // MCSymbol.  This also ensures we don't need padding between the name and
  // symbol.
  assert(alignOf<MCSymbol>() <= alignof(NameEntryTy *) &&
         "Bad alignment of MCSymbol");
  void *Storage = Ctx.allocate(Size, alignof(NameEntryTy *));
  NameEntryTy **Start = static_cast<NameEntryTy**>(Storage);
  NameEntryTy **End = Start + (Name ? 1 : 0);
  return End;
}

void MCSymbol::setVariableValue(const MCExpr *Value) {
  assert(!IsUsed && "Cannot set a variable that has already been used.");
  assert(Value && "Invalid variable value!");
  this->Value = Value;
  SectionOrFragment = nullptr;
}

void MCSymbol::print(raw_ostream &OS, const MCAsmInfo *MAI) const {
  // The name for this MCSymbol is required to be a valid target name.  However,
  // some targets support quoting names with funny characters.  If the name
  // contains a funny character, then print it quoted.
  StringRef Name = getName();
  if (!MAI || MAI->isValidUnquotedName(Name)) {
    OS << Name;
    return;
  }

  if (MAI && !MAI->supportsNameQuoting())
    report_fatal_error("Symbol name with unsupported characters");

  OS << '"';
  for (char C : Name) {
    if (C == '\n')
      OS << "\\n";
    else if (C == '"')
      OS << "\\\"";
    else
      OS << C;
  }
  OS << '"';
}

#if !defined(NDEBUG) || defined(LLVM_ENABLE_DUMP)
void MCSymbol::dump() const { dbgs() << *this; }
#endif
