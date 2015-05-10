-- automatically generated by BNF Converter
module Main where


import System.IO ( stdin, stderr, hPutStrLn, hGetContents )
import System.Environment ( getArgs, getProgName )
import System.Exit ( exitFailure, exitSuccess, exitWith )
import GHC.IO.Exception ( ExitCode )
import qualified Lexgramatyka
import qualified Pargramatyka
import qualified Skelgramatyka
import qualified Printgramatyka
import Absgramatyka
import ErrM

import Control.Monad.Except
import Control.Monad.RWS
import qualified Srodowisko as Sr
import qualified Stan as St
import Typy
import Data.Complex
import Data.Bits
import Data.Dynamic
type ParseFun a = [Lexgramatyka.Token] -> Err a
myLLexer = Pargramatyka.myLexer
type Verbosity = Int
-- koniec zmudnych definicji



type Przetwarzacz a = ExceptT String (RWST Sr.Srodowisko () St.Stan IO) a


putStrV :: Verbosity -> String -> IO ()
putStrV v s = if v > 1 then putStrLn s else return ()

runFile :: Verbosity -> ParseFun Program -> FilePath -> IO ()
runFile v p f = putStrLn f >> readFile f >>= run v p

run :: Verbosity -> ParseFun Program -> String -> IO ()
run v p s = let ts = myLLexer s in case  p ts of
           Bad s    -> do putStrLn s
                          exitFailure
           Ok  tree -> do hPutStrLn stderr "Udalo sie sparsowac!"
                          z <- runRWST ( runExceptT $ zinterpretuj tree)
                               Sr.srodowiskoZero St.stanZero
                          hPutStrLn stderr (show z)
                          exitSuccess


showTree :: (Show a, Printgramatyka.Print a) => Int -> a -> IO ()
showTree v tree
 = do
      putStrV v $ "\n[Abstract Syntax]\n\n" ++ show tree
      putStrV v $ "\n[Linearized tree]\n\n" ++ Printgramatyka.printTree tree

main :: IO ()
main = do args <- getArgs
          case args of
            [] -> hGetContents stdin >>= run 2 Pargramatyka.pProgram
            "-s":fs -> mapM_ (runFile 0 Pargramatyka.pProgram) fs
            fs -> mapM_ (runFile 2 Pargramatyka.pProgram) fs

podaj_komorke :: Expr -> Przetwarzacz Komorka
podaj_komorke expr = do
  case expr of
   Variable id -> do
     Just lok <- asks (Sr.daj_lokacje id)
     return KomZm { lok = lok }
   ETableElement id expr -> do
     return undefined
   EMatrixElement id expr0 expr1 -> do
     return undefined
   _ -> do
     throwError
       "Komorka pamieci moze dotyczyc tylko zmiennej lub tablicy/macierzy"



oblicz_wyrazenie :: Expr -> Przetwarzacz TypQCL
oblicz_wyrazenie e = do
  case e of
   Variable id -> do
     Just lok <- asks (Sr.daj_lokacje id)
     Just wynik <- gets (St.daj_wartosc lok )
     return wynik
   EFCall id expr -> do
     return undefined
   ETableElement id expr -> do
     return undefined
   EMatrixElement id expr0 expr1 -> do
     return undefined
   EListaOdDo id expr0 expr1 -> do
     return undefined
   ELiczbaElementowListy id expr0 expr1 -> do -- x[z::y]
     return undefined
   ETrzecieListy id expr0 expr1 -> do      -- x[z..y]
     return undefined
   EListyBez id expr0 expr1 -> do           -- x[z\y]
     throwError "ala ma kota"
     return undefined
   EConst c -> do               -- po prostu stala
     case c of
      (CString x) -> do
        return $ PT (Napis x)
      (CBoolTrue) -> do
        return $ PT (ZmiennaLogiczna True)
      (CBoolFalse) -> do
        return $ PT (ZmiennaLogiczna False)
      (CJustConst x) ->
        return $ PT (Liczba x)
      (CConstComplexPair cc0 cc1) -> do
        return $ PT (ZmiennaZespolona ((:+) cc0 cc1))
   EEq expr0 expr1 -> do                       -- x == z
     pierwsze <- oblicz_wyrazenie expr0
     drugie <- oblicz_wyrazenie expr1
     return $ pak $ pierwsze == drugie
   ENeq expr0 expr1 -> do                     -- x != z
     x <- oblicz_wyrazenie $ EEq expr0 expr1
     return $ pak $ not $ (odpak :: TypQCL -> Bool) x
   ELe expr0 expr1 -> do                      -- x < y
     x <- oblicz_wyrazenie expr0
     y <- oblicz_wyrazenie expr1
     return $ pak $ x < y
   ELEq expr0 expr1 -> do                     -- x <= y
     x <- oblicz_wyrazenie expr0
     y <- oblicz_wyrazenie expr1
     return $ pak $ x <= y
   EGr expr0 expr1 -> do                      -- x > y
     x <- oblicz_wyrazenie expr0
     y <- oblicz_wyrazenie expr1
     return $ pak $ x > y
   EGrEq expr0 expr1 -> do                    -- x >= y
     x <- oblicz_wyrazenie expr0
     y <- oblicz_wyrazenie expr1
     return $ pak $ x >= y
   EOr expr0 expr1 -> do                      -- x or y
     x <- oblicz_wyrazenie expr0
     y <- oblicz_wyrazenie expr1
     return $ pak $ odpak y || odpak x
   EAnd expr0 expr1 -> do                     -- x and y
     x <- oblicz_wyrazenie expr0
     y <- oblicz_wyrazenie expr1
     return $ pak $ odpak y && odpak x
   EXor expr0 expr1 -> do                     -- x xor y
     x <- oblicz_wyrazenie expr0
     y <- oblicz_wyrazenie expr1
     case x of
      PT (Liczba a) -> do
        return $ pak $ xor a (odpak y)
      PT (ZmiennaLogiczna a) -> do
        return $ pak $ xor a ((odpak :: TypQCL -> Bool) y)
   ENot expr -> do                          -- not y
     x <- oblicz_wyrazenie expr
     return $ pak $ not $ odpak x
   EAdd expr0 expr1 -> do                     -- x + y
     x <- oblicz_wyrazenie expr0
     y <- oblicz_wyrazenie expr1
     case x of
      PT (Liczba a) -> do
        return $ pak $ a + (odpak y)
      PT (ZmiennaZespolona a) -> do
        return $ pak $ a + (odpak y)
   ESubtract expr0 expr1 -> do                -- x - y
     x <- oblicz_wyrazenie expr0
     y <- oblicz_wyrazenie expr1
     case x of
      PT (Liczba a) -> do
        return $ pak $ a - (odpak y)
      PT (ZmiennaZespolona a) -> do
        return $ pak $ a - (odpak y)
   EStringConcat expr0 expr1 -> do            -- x & y
     return undefined
   ETimes expr0 expr1 -> do                   -- x * y
     x <- oblicz_wyrazenie expr0
     y <- oblicz_wyrazenie expr1
     case x of
      PT (Liczba a) -> do
        return $ pak $ a * (odpak y)
      PT (ZmiennaZespolona a) -> do
        return $ pak $ a * (odpak y)
   EDiv expr0 expr1 -> do                     -- x / y
     x <- oblicz_wyrazenie expr0
     y <- oblicz_wyrazenie expr1
     case x of
      PT (Liczba a) -> do
        if a == 0 then
           (throwError "Dzielenie przez zero!")
        else
           (return $ pak $ div a (odpak y))
      PT (ZmiennaZespolona a) -> do
        if (magnitude a) == 0 then
           (throwError "Dzielenie przez zero!")
        else
           (return $ pak $ a / (odpak y))
   EMod expr0 expr1 -> do                     -- x mod y
     x <- oblicz_wyrazenie expr0
     y <- oblicz_wyrazenie expr1
     case y of
      PT (Liczba a) -> do
        if a == 0 then
          (throwError "Modulo zero?")
        else
          (return $ pak $ mod (odpak x) a)
   EPow expr0 expr1 -> do                     -- x ^ y
     return undefined
   EUnaryMinus expr -> do                   -- -x
     x <- oblicz_wyrazenie expr
     case x of
      PT (Liczba a) -> do
       return $ pak $ -1 * a
      PT (ZmiennaZespolona a) -> do
       return $ pak $ -1 * a
   ESize expr -> do                         -- #x
     return undefined

wloz_def :: Ident -> (TypQCL) -> Przetwarzacz Sr.Srodowisko
wloz_def id wartosc = do
  lok <- gets St.daj_wolna_lok
  modify St.zwieksz_wolna_lok
  modify $ St.dodaj_wartosc lok wartosc
  srod <- ask
  return $ Sr.zmien_srodowisko id lok srod

oblicz_def :: Def -> Przetwarzacz Sr.Srodowisko
oblicz_def def = do
  case def of
   DefConstDef (ClassicalConstDef id expr) -> do
     ile <- oblicz_wyrazenie expr
     wloz_def id ile
   DefConstDef (QuantumConstDef typ id) -> do
     return undefined
   VarDefDef (JustVarDef typ id) -> do
     case typ of
      (SimpleType TString) -> do
        wloz_def id (pak "")
      (SimpleType TBoolean) -> do
        wloz_def id (pak False)
      (SimpleType TInt) -> do
        wloz_def id ((pak :: Integer -> TypQCL) 0)
      (SimpleType TComplex) -> do
        wloz_def id ((pak :: Complex Double -> TypQCL) $ (:+) 0 0)
   VarDefDef (VarDefAss typ id expr) -> do
     ile <- oblicz_wyrazenie expr
     wloz_def id ile
   VarDefDef (VarDefTable typ id expr) -> do
     PT (Liczba ile) <- oblicz_wyrazenie expr
     wloz_def id $ ZT (Tab { tablica = [] :: [ProstyTypQCL],
                             rozmiar = ile })
   FunDef typ id argy cialo -> do
     throwError "definicja funkcji nie zostala jeszcze zaimplementowana"
     return undefined
   ProcDef id argy cialo -> do
     return undefined
   OperatorDef id argy cialo -> do
     return undefined
   QufunctOperatorDef id argy cialo -> do
     return undefined
   CondOperatorDef id argy cialo -> do
     return undefined
   QufunctDef id argy cialo -> do
     return undefined
   CondQufunctDef id argy cialo -> do
     return undefined
   ExternOpDef id argy -> do
     return undefined
   ExternQufunctDef id argy -> do
     return undefined
   ExternCondOpDef id argy -> do
     return undefined
   ExternCondQufunctDef id argy -> do
     return undefined

zinterpretuj :: Program -> Przetwarzacz ()
zinterpretuj (QCLProgram (def:resztadef) stmt) = do {
  sr <- oblicz_def def;
  local (const sr) (zinterpretuj (QCLProgram resztadef stmt));
  } `catchError` zlap_wyjatek

zinterpretuj (QCLProgram [] (stmt:stmt2)) = do {
  zinterpretuj_stmt stmt;
  zinterpretuj (QCLProgram [] stmt2);
  } `catchError` zlap_wyjatek

zinterpretuj this@(QCLProgram [] []) = do {
  srod <- ask;
  stan <- get;
  lift $ lift $ hPutStrLn stderr "Koniec.";
  lift $ lift $ hPutStrLn stderr $ "STAN " ++ (show stan);
  lift $ lift $ hPutStrLn stderr $ "SRODOWISKO " ++ show (srod);
  return ()
  } `catchError` zlap_wyjatek


zlap_wyjatek :: String -> ExceptT String (RWST Sr.Srodowisko () St.Stan IO) ()
zlap_wyjatek x = do
  lift $ lift $ putStrLn ("BLAD " ++ x)
  srod <- ask
  stan <- get
  lift $ lift $ hPutStrLn stderr ("SRODOWISKO " ++ (show srod) ++ "\nSTAN " ++ (show stan))

zinterpretuj_stmt :: Stmt -> Przetwarzacz ()
zinterpretuj_stmt stmt = do
  case stmt of
   WhileLoop expr blok -> do
     x <- oblicz_wyrazenie expr
     case x of
      PT (ZmiennaLogiczna True) -> do
        zinterpretuj_blok blok
        zinterpretuj_stmt stmt
      PT (ZmiennaLogiczna False) -> do
        return ()
      _ ->
        throwError "To nigdy nie wystapi, poniewaz expr daje wartosc logiczna"
   ConditionalBranch expr blok -> do
     zinterpretuj_stmt (ConditionalBranchElse expr blok (JustBlock []))
   ConditionalBranchElse expr blok0 blok1 -> do
     x <- oblicz_wyrazenie expr
     case x of
      PT (ZmiennaLogiczna True) -> do
        zinterpretuj_blok blok0
      PT (ZmiennaLogiczna False) -> do
        zinterpretuj_blok blok1
      _ -> do
        throwError "To nigdy nie wystapi, poniewaz expr daje wartosc logiczna"
   Print [] -> do
     return ()
   Print (wyrazenie:wyrazenia) -> do
     wynik <- oblicz_wyrazenie wyrazenie
     lift $ lift $ putStr $ show wynik
     zinterpretuj_stmt (Print wyrazenia)
   UnitaryOpInvCall id expr -> do
     return undefined
   Expression expr -> do
     oblicz_wyrazenie expr
     return ()
   Assignment expr0 expr1 -> do
     kom <- podaj_komorke expr0
     wartosc <- oblicz_wyrazenie expr1
     modify $ St.dodaj_wartosc_kom kom wartosc
   FanoutSugar expr0 operatorFanout expr1 -> do
     return undefined
   ForLoop id expr0 expr1 blok -> do
     zinterpretuj_stmt (ForStepLoop id expr0 expr1 (EConst (CJustConst 1)) blok)
   ForStepLoop id expr0 expr1 expr2 (JustBlock wyrazenia)  -> do
     zinterpretuj_stmt (Assignment (Variable id) expr0)
     zinterpretuj_stmt $
       (WhileLoop
        (ENeq
         (Variable id)
         (EAdd expr1 expr2))
        (JustBlock (wyrazenia ++ [Assignment (Variable id)
                                  (EAdd
                                   (Variable id)
                                   expr2)])))
   UntilLoop blok expr -> do
     zinterpretuj_blok blok
     zinterpretuj_stmt (WhileLoop expr blok)
   ReturnExpr expr -> do
     return undefined
   InputExpr expr id -> do
     return undefined
   InputNoExpr id -> do
     return undefined
   Exit expr -> do
     PT (Liczba x) <- oblicz_wyrazenie expr
     lift $ lift $ exitWith $ (read :: String -> GHC.IO.Exception.ExitCode) (show x)
     return ()
   MeasureNoIdent expr -> do
     return undefined
   MeasureIdent expr id -> do
     return undefined
   Reset -> do
     return undefined
   List [id] -> do
     return undefined
   DumpExpr expr -> do
     return undefined
   DumpNoExpr -> do
     return undefined
   LoadExpr expr -> do
     return undefined
   LoadNoExpr -> do
     return undefined
   SaveExpr expr -> do
     return undefined
   SaveNoExpr -> do
     return undefined
   Shell -> do
     return undefined
   SetExpr op expr -> do
     return undefined
   Semicolon -> do
     return ()

-- instrukcje to tak jakby wskazowki
zinterpretuj_blok :: Block -> Przetwarzacz ()
zinterpretuj_blok (JustBlock wskazowki) = do
  mapM_ zinterpretuj_stmt wskazowki
