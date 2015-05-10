module Skelgramatyka where

-- Haskell module generated by the BNF converter

import Absgramatyka
import ErrM
type Result = Err String

failure :: Show a => a -> Result
failure x = Bad $ "Undefined case: " ++ show x

transIdent :: Ident -> Result
transIdent x = case x of
  Ident str  -> failure x


transProgram :: Program -> Result
transProgram x = case x of
  QCLProgram defs stmts  -> failure x


transConst :: Const -> Result
transConst x = case x of
  CJustConst n  -> failure x
  CConstComplexPair d1 d2  -> failure x
  CBoolTrue  -> failure x
  CBoolFalse  -> failure x
  CString str  -> failure x


transExpr :: Expr -> Result
transExpr x = case x of
  Variable id  -> failure x
  EFCall id exprs  -> failure x
  ETableElement id expr  -> failure x
  EMatrixElement id expr1 expr2  -> failure x
  EListaOdDo id expr1 expr2  -> failure x
  ELiczbaElementowListy id expr1 expr2  -> failure x
  ETrzecieListy id expr1 expr2  -> failure x
  EListyBez id expr1 expr2  -> failure x
  EConst const  -> failure x
  EEq expr1 expr2  -> failure x
  ENeq expr1 expr2  -> failure x
  ELe expr1 expr2  -> failure x
  ELEq expr1 expr2  -> failure x
  EGr expr1 expr2  -> failure x
  EGrEq expr1 expr2  -> failure x
  EOr expr1 expr2  -> failure x
  EAnd expr1 expr2  -> failure x
  EXor expr1 expr2  -> failure x
  ENot expr  -> failure x
  EAdd expr1 expr2  -> failure x
  ESubtract expr1 expr2  -> failure x
  EStringConcat expr1 expr2  -> failure x
  ETimes expr1 expr2  -> failure x
  EDiv expr1 expr2  -> failure x
  EMod expr1 expr2  -> failure x
  EPow expr1 expr2  -> failure x
  EUnaryMinus expr  -> failure x
  ESize expr  -> failure x


transOption :: Option -> Result
transOption x = case x of
  JustOption id  -> failure x


transStmt :: Stmt -> Result
transStmt x = case x of
  UnitaryOpInvCall id exprs  -> failure x
  Expression expr  -> failure x
  Assignment expr1 expr2  -> failure x
  FanoutSugar expr1 fanoutsugarop2 expr3  -> failure x
  ForLoop id expr1 expr2 block3  -> failure x
  ForStepLoop id expr1 expr2 expr3 block4  -> failure x
  WhileLoop expr block  -> failure x
  UntilLoop block expr  -> failure x
  ConditionalBranch expr block  -> failure x
  ConditionalBranchElse expr block1 block2  -> failure x
  ReturnExpr expr  -> failure x
  InputExpr expr id  -> failure x
  InputNoExpr id  -> failure x
  Print exprs  -> failure x
  Exit expr  -> failure x
  MeasureNoIdent expr  -> failure x
  MeasureIdent expr id  -> failure x
  Reset  -> failure x
  List ids  -> failure x
  DumpExpr expr  -> failure x
  DumpNoExpr  -> failure x
  LoadExpr expr  -> failure x
  LoadNoExpr  -> failure x
  SaveExpr expr  -> failure x
  SaveNoExpr  -> failure x
  Shell  -> failure x
  SetExpr option expr  -> failure x
  Semicolon  -> failure x


transFanoutSugarOp :: FanoutSugarOp -> Result
transFanoutSugarOp x = case x of
  FanoutRight  -> failure x
  FanoutLeft  -> failure x
  FanoutSwap  -> failure x


transType :: Type -> Result
transType x = case x of
  SimpleType st  -> failure x
  Vector st  -> failure x
  Matrix st  -> failure x
  Tensor st n  -> failure x


transST :: ST -> Result
transST x = case x of
  TString  -> failure x
  TBoolean  -> failure x
  TInt  -> failure x
  TReal  -> failure x
  TComplex  -> failure x
  TQureg  -> failure x
  TQuvoid  -> failure x
  TQuConst  -> failure x
  TQuscratch  -> failure x
  TQucond  -> failure x


transConstDef :: ConstDef -> Result
transConstDef x = case x of
  ClassicalConstDef id expr  -> failure x
  QuantumConstDef type' id  -> failure x


transVarDef :: VarDef -> Result
transVarDef x = case x of
  JustVarDef type' id  -> failure x
  VarDefAss type' id expr  -> failure x
  VarDefTable type' id expr  -> failure x


transArgDef :: ArgDef -> Result
transArgDef x = case x of
  JustArgDef type' id  -> failure x


transConstOrVar :: ConstOrVar -> Result
transConstOrVar x = case x of
  ConstDefListItem constdef  -> failure x
  VarDefListItem vardef  -> failure x


transBody :: Body -> Result
transBody x = case x of
  JustBody constorvars stmts  -> failure x


transDef :: Def -> Result
transDef x = case x of
  DefConstDef constdef  -> failure x
  VarDefDef vardef  -> failure x
  FunDef type' id argdefs body  -> failure x
  ProcDef id argdefs body  -> failure x
  OperatorDef id argdefs body  -> failure x
  QufunctOperatorDef id argdefs body  -> failure x
  CondOperatorDef id argdefs body  -> failure x
  QufunctDef id argdefs body  -> failure x
  CondQufunctDef id argdefs body  -> failure x
  ExternOpDef id argdefs  -> failure x
  ExternQufunctDef id argdefs  -> failure x
  ExternCondOpDef id argdefs  -> failure x
  ExternCondQufunctDef id argdefs  -> failure x


transBlock :: Block -> Result
transBlock x = case x of
  JustBlock stmts  -> failure x



