

module Absgramatyka where

-- Haskell module generated by the BNF converter




newtype Ident = Ident String deriving (Eq,Ord,Show,Read)
data Program =
   QCLProgram [Def] [Stmt]
  deriving (Eq,Ord,Show,Read)

data Const =
   CJustConst Integer
 | CConstComplexPair Double Double
 | CBoolTrue
 | CBoolFalse
 | CString String
  deriving (Eq,Ord,Show,Read)

data Expr =
   Variable Ident
 | EFCall Ident [Expr]
 | ETableElement Ident Expr
 | EMatrixElement Ident Expr Expr
 | EListaOdDo Ident Expr Expr
 | ELiczbaElementowListy Ident Expr Expr
 | ETrzecieListy Ident Expr Expr
 | EListyBez Ident Expr Expr
 | EConst Const
 | EEq Expr Expr
 | ENeq Expr Expr
 | ELe Expr Expr
 | ELEq Expr Expr
 | EGr Expr Expr
 | EGrEq Expr Expr
 | EOr Expr Expr
 | EAnd Expr Expr
 | EXor Expr Expr
 | ENot Expr
 | EAdd Expr Expr
 | ESubtract Expr Expr
 | EStringConcat Expr Expr
 | ETimes Expr Expr
 | EDiv Expr Expr
 | EMod Expr Expr
 | EPow Expr Expr
 | EUnaryMinus Expr
 | ESize Expr
  deriving (Eq,Ord,Show,Read)

data Option =
   JustOption Ident
  deriving (Eq,Ord,Show,Read)

data Stmt =
   UnitaryOpInvCall Ident [Expr]
 | Expression Expr
 | Assignment Expr Expr
 | FanoutSugar Expr FanoutSugarOp Expr
 | ForLoop Ident Expr Expr Block
 | ForStepLoop Ident Expr Expr Expr Block
 | WhileLoop Expr Block
 | UntilLoop Block Expr
 | ConditionalBranch Expr Block
 | ConditionalBranchElse Expr Block Block
 | ReturnExpr Expr
 | InputExpr Expr Ident
 | InputNoExpr Ident
 | Print [Expr]
 | Exit Expr
 | MeasureNoIdent Expr
 | MeasureIdent Expr Ident
 | Reset
 | List [Ident]
 | DumpExpr Expr
 | DumpNoExpr
 | LoadExpr Expr
 | LoadNoExpr
 | SaveExpr Expr
 | SaveNoExpr
 | Shell
 | SetExpr Option Expr
 | Semicolon
  deriving (Eq,Ord,Show,Read)

data FanoutSugarOp =
   FanoutRight
 | FanoutLeft
 | FanoutSwap
  deriving (Eq,Ord,Show,Read)

data Type =
   SimpleType ST
 | Vector ST
 | Matrix ST
 | Tensor ST Integer
  deriving (Eq,Ord,Show,Read)

data ST =
   TString
 | TBoolean
 | TInt
 | TReal
 | TComplex
 | TQureg
 | TQuvoid
 | TQuConst
 | TQuscratch
 | TQucond
  deriving (Eq,Ord,Show,Read)

data ConstDef =
   ClassicalConstDef Ident Expr
 | QuantumConstDef Type Ident
  deriving (Eq,Ord,Show,Read)

data VarDef =
   JustVarDef Type Ident
 | VarDefAss Type Ident Expr
 | VarDefTable Type Ident Expr
  deriving (Eq,Ord,Show,Read)

data ArgDef =
   JustArgDef Type Ident
  deriving (Eq,Ord,Show,Read)

data ConstOrVar =
   ConstDefListItem ConstDef
 | VarDefListItem VarDef
  deriving (Eq,Ord,Show,Read)

data Body =
   JustBody [ConstOrVar] [Stmt]
  deriving (Eq,Ord,Show,Read)

data Def =
   DefConstDef ConstDef
 | VarDefDef VarDef
 | FunDef Type Ident [ArgDef] Body
 | ProcDef Ident [ArgDef] Body
 | OperatorDef Ident [ArgDef] Body
 | QufunctOperatorDef Ident [ArgDef] Body
 | CondOperatorDef Ident [ArgDef] Body
 | QufunctDef Ident [ArgDef] Body
 | CondQufunctDef Ident [ArgDef] Body
 | ExternOpDef Ident [ArgDef]
 | ExternQufunctDef Ident [ArgDef]
 | ExternCondOpDef Ident [ArgDef]
 | ExternCondQufunctDef Ident [ArgDef]
  deriving (Eq,Ord,Show,Read)

data Block =
   JustBlock [Stmt]
  deriving (Eq,Ord,Show,Read)

