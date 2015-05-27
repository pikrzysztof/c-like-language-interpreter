module InterpreterAbsgramatyki where
import System.Exit (exitWith, exitSuccess)
import GHC.IO.Exception (ExitCode)
import Absgramatyka
import Typy
import Data.Bits
import qualified Stan as St
import qualified Srodowisko as Sr
import Data.Complex
import Control.Monad.Except
import Control.Monad.RWS
import TypyZalezne
import Rozmaitosci

podaj_komorke :: Expr -> Przetwarzacz Komorka
podaj_komorke expr = do
  case expr of
   Variable ident -> do
     Just lokacja <- asks (Sr.daj_lokacje ident)
     return KomZm { lok = lokacja }
   ETableElement ident exprw -> do
     lift $ lift $ putStrLn ("nie zaimplementowano " ++ (show expr))
     return undefined
   EMatrixElement ident expr0 expr1 -> do
     lift $ lift $ putStrLn ("nie zaimplementowano " ++ (show expr))
     return undefined
   _ -> do
     throwError
       "Komorka pamieci moze dotyczyc tylko zmiennej lub tablicy/macierzy"

zastosuj_operator :: Pakowalny a => (TypQCL -> TypQCL -> a) -> Expr ->
                     Expr -> Przetwarzacz TypQCL
zastosuj_operator op a b = do
  x <- oblicz_wyrazenie a
  y <- oblicz_wyrazenie b
  return $ pak $ op x y

oblicz_wyrazenie :: Expr -> Przetwarzacz TypQCL
oblicz_wyrazenie e = do
  case e of
   Variable ident -> do
     Just lokacja <- asks (Sr.daj_lokacje ident)
     Just wynik <- gets (St.daj_wartosc lokacja)
     return wynik
   EFCall ident argumenty -> do
     Just lokacja <- asks $ Sr.daj_lokacje ident
     Just fn <- gets $ St.daj_podprogram lokacja
     wolne_lok <- gets $ St.daj_wolne_lok $ toInteger $ length argumenty
     modify $ St.zajmij_wolne_lok wolne_lok
     obliczone <- mapM oblicz_wyrazenie argumenty
     modify $ St.dodaj_wartosci wolne_lok obliczone
     local (Sr.zmien_srodowisko (St.arg_ident fn) wolne_lok)
       (zinterpretuj_podprogram $ St.cialo fn)
     wyn <- gets St.daj_wynik_funkcji
     modify St.usun_wynik_funkcji
     modify $ St.usun_lokacje_i_nowsze wolne_lok
     return wyn
   ETableElement ident expr -> do
     lift $ lift $ putStrLn ("nie zaimplementowano " ++ (show e))
     return undefined
   EMatrixElement ident expr0 expr1 -> do
     lift $ lift $ putStrLn ("nie zaimplementowano " ++ (show e))
     return undefined
   EListaOdDo ident expr0 expr1 -> do
     lift $ lift $ putStrLn ("nie zaimplementowano " ++ (show e))
     return undefined
   ECalkowitaElementowListy ident expr0 expr1 -> do -- x[z::y]
     lift $ lift $ putStrLn ("nie zaimplementowano " ++ (show e))
     return undefined
   ETrzecieListy ident expr0 expr1 -> do      -- x[z..y]
     lift $ lift $ putStrLn ("nie zaimplementowano " ++ (show e))
     return undefined
   EListyBez ident expr0 expr1 -> do           -- x[z\y]
     lift $ lift $ putStrLn ("nie zaimplementowano " ++ (show e))
     return undefined
   EConst c -> do               -- po prostu stala
     case c of
      (CString x) -> do
        return $ pak x
      (CBoolTrue) -> do
        return $ pak True
      (CBoolFalse) -> do
        return $ pak False
      (CJustConst x) ->
        return $ pak x
      (CConstComplexPair cc0 cc1) -> do
        return $ pak $ (:+) cc0 cc1
   EEq expr0 expr1 -> do                       -- x == z
     zastosuj_operator (==) expr0 expr1
   ENeq expr0 expr1 -> do                     -- x != z
     zastosuj_operator (/=) expr0 expr1
   ELe expr0 expr1 -> do                      -- x < y
     zastosuj_operator (<) expr0 expr1
   ELEq expr0 expr1 -> do                     -- x <= y
     zastosuj_operator (<=) expr0 expr1
   EGr expr0 expr1 -> do                      -- x > y
     zastosuj_operator (>) expr0 expr1
   EGrEq expr0 expr1 -> do                    -- x >= y
     zastosuj_operator (>=) expr0 expr1
   EOr expr0 expr1 -> do                      -- x or y
     zastosuj_operator (.|.) expr0 expr1
   EAnd expr0 expr1 -> do                     -- x and y
     zastosuj_operator (.&.) expr0 expr1
   EXor expr0 expr1 -> do                     -- x xor y
     zastosuj_operator xor expr0 expr1
   ENot expr -> do                          -- not y
     x <- oblicz_wyrazenie expr
     return $ negate x
   EAdd expr0 expr1 -> do                     -- x + y
     zastosuj_operator (+) expr0 expr1
   ESubtract expr0 expr1 -> do                -- x - y
     zastosuj_operator (-) expr0 expr1
   EStringConcat expr0 expr1 -> do            -- x & y
     zastosuj_operator (+) expr0 expr1
   ETimes expr0 expr1 -> do                   -- x * y
     zastosuj_operator (*) expr0 expr1
   ESize expr -> do                         -- #x
     lift $ lift $ putStrLn ("nie zaimplementowano " ++ (show e))
     return undefined
   EUnaryMinus expr -> do                   -- -x
     x <- oblicz_wyrazenie expr
     return $ negate x
   EPow expr0 expr1 -> do                     -- x ^ y
     x <- oblicz_wyrazenie expr0
     y <- oblicz_wyrazenie expr1
     case y of
      (PT (Calkowita a)) -> do {
        if (a >= (0 :: Integer) && ((odpak x) > (0 :: Integer))) || a > 0 then
           (return $ (pak :: Integer -> TypQCL) $
            ((odpak :: TypQCL -> Integer) x) ^ a)
        else
           (throwError $ "*Niedozwolone* jest potęgowanie takich liczb!");
        }
      (PT (Zespolona b)) -> do
        return $ pak $ (odpak x) ** b
      _ -> do
        lift $ lift $ putStrLn ("nie mozna podniesc do potegi " ++ (show e))
        undefined
   EDiv expr0 expr1 -> do                     -- x / y
     x <- oblicz_wyrazenie expr0
     y <- oblicz_wyrazenie expr1
     case y of
      PT (Calkowita a) -> do {
        if a == 0 then
           (throwError $ "Dzielenie przez zero w " ++ (show e))
        else
           (return $ pak $ div (odpak x) a);
      }
      PT (Zespolona a) -> do {
        if (magnitude a) == 0 then
           (throwError $ "Dzielenie przez zero w " ++ (show e))
        else
           (return $ pak $ a / (odpak y));
      }
      _ -> do
        lift $ lift $ putStrLn ("nie mozna podzielic " ++ (show e))
        return undefined
   EMod expr0 expr1 -> do                     -- x mod y
     x <- oblicz_wyrazenie expr0
     y <- oblicz_wyrazenie expr1
     case y of
      PT (Calkowita a) -> do {
        if a == 0 then
          (throwError $ "Modulo zero w " ++ (show e))
        else
          (return $ pak $ (odpak y) `mod` a);
      }
      _ -> do
        lift $ lift $ putStrLn ("nie mozna modnac " ++ (show e))
        return undefined

zinterpretuj_stmt_jesli_nie_ret :: Stmt -> Przetwarzacz ()
zinterpretuj_stmt_jesli_nie_ret stmt = do
  wyn_return <- gets St.daj_wynik_funkcji
  case wyn_return of
   PT Nic ->
     zinterpretuj_stmt stmt
   _ -> return ()

zinterpretuj_stmt :: Stmt -> Przetwarzacz ()
zinterpretuj_stmt stmt = do
  case stmt of
   WhileLoop expr blok -> do
     x <- oblicz_wyrazenie expr
     case x of
      PT (Logiczna True) -> do
        zinterpretuj_blok blok
        zinterpretuj_stmt_jesli_nie_ret stmt
      PT (Logiczna False) -> do
        return ()
      _ ->
        throwError "To nigdy nie wystapi, poniewaz expr daje wartosc logiczna"
   ConditionalBranch expr blok -> do
     zinterpretuj_stmt_jesli_nie_ret
       (ConditionalBranchElse expr blok (JustBlock []))
   ConditionalBranchElse expr blok0 blok1 -> do
     x <- oblicz_wyrazenie expr
     case x of
      PT (Logiczna True) -> do
        zinterpretuj_blok blok0
      PT (Logiczna False) -> do
        zinterpretuj_blok blok1
      _ -> do
        throwError "To nigdy nie wystapi, poniewaz expr daje wartosc logiczna"
   Print wyrazenia -> do
     wyliczone <- mapM oblicz_wyrazenie wyrazenia
     lift $ lift $ putStr $ concatMap show wyliczone
     return ()
   UnitaryOpInvCall ident expr -> do
     lift $ lift $ putStrLn ("nie mozna wykonac " ++ (show stmt))
     return undefined
   Expression expr -> do
     _ <- oblicz_wyrazenie expr
     return ()
   Assignment expr0 expr1 -> do
     kom <- podaj_komorke expr0
     wartosc <- oblicz_wyrazenie expr1
     modify $ St.dodaj_wartosc_kom kom wartosc
   FanoutSugar expr0 operatorFanout expr1 -> do
     lift $ lift $ putStrLn ("nie mozna wykonac " ++ (show stmt))
     return undefined
   ForLoop ident expr0 expr1 blok -> do
     zinterpretuj_stmt_jesli_nie_ret
       (ForStepLoop ident expr0 expr1 (EConst (CJustConst 1)) blok)
   ForStepLoop ident expr0 expr1 expr2 (JustBlock wyrazenia)  -> do
     zinterpretuj_stmt_jesli_nie_ret (Assignment (Variable ident) expr0)
     zinterpretuj_stmt_jesli_nie_ret $
       (WhileLoop
        (ENeq
         (Variable ident)
         (EAdd expr1 expr2))
        (JustBlock (wyrazenia ++ [Assignment (Variable ident)
                                  (EAdd
                                   (Variable ident)
                                   expr2)])))
   UntilLoop blok expr -> do
     zinterpretuj_blok blok
     zinterpretuj_stmt_jesli_nie_ret (WhileLoop expr blok)
   ReturnExpr expr -> do
     x <- oblicz_wyrazenie expr
     modify $ St.wloz_wynik_funkcji x
     return ()
   InputExpr expr ident -> do
     lift $ lift $ putStrLn ("nie mozna wykonac " ++ (show stmt))
     return undefined
   InputNoExpr ident -> do
     lift $ lift $ putStrLn ("nie mozna wykonac " ++ (show stmt))
     return undefined
   Exit expr -> do
     a <- oblicz_wyrazenie expr
     case a of
      (PT (Calkowita x)) ->
        lift $ lift $ exitWith $
        (read :: String -> GHC.IO.Exception.ExitCode) (show x)
      (PT (Napis x)) -> do
        lift $ lift $ putStrLn x
        _ <- lift $ lift exitSuccess
        return ()
      _ -> undefined
   MeasureNoIdent expr -> do
     lift $ lift $ putStrLn ("nie mozna wykonac " ++ (show stmt))
     return undefined
   MeasureIdent expr ident -> do
     lift $ lift $ putStrLn ("nie mozna wykonac " ++ (show stmt))
     return undefined
   Reset -> do
     lift $ lift $ putStrLn ("nie mozna wykonac " ++ (show stmt))
     return undefined
   List [] -> return undefined
   List (ident:identy) -> do
     Just lokac <- asks $ Sr.daj_lokacje ident
     Just wart <- gets $ St.daj_wartosc lokac
     lift $ lift $ putStrLn $ "Identyfikator " ++ (show ident) ++
       " lokacja " ++ (show lokac) ++ " wartosc " ++ (show wart)
     zinterpretuj_stmt_jesli_nie_ret (List identy)
   DumpExpr expr -> do
     lift $ lift $ putStrLn ("nie mozna wykonac " ++ (show stmt))
     return undefined
   DumpNoExpr -> do
     lift $ lift $ putStrLn ("nie mozna wykonac " ++ (show stmt))
     return undefined
   LoadExpr expr -> do
     lift $ lift $ putStrLn ("nie mozna wykonac " ++ (show stmt))
     return undefined
   LoadNoExpr -> do
     lift $ lift $ putStrLn ("nie mozna wykonac " ++ (show stmt))
     return undefined
   SaveExpr expr -> do
     lift $ lift $ putStrLn ("nie mozna wykonac " ++ (show stmt))
     return undefined
   SaveNoExpr -> do
     lift $ lift $ putStrLn ("nie mozna wykonac " ++ (show stmt))
     return undefined
   Shell -> do
     lift $ lift $ putStrLn ("nie mozna wykonac " ++ (show stmt))
     return undefined
   SetExpr op expr -> do
     lift $ lift $ putStrLn ("nie mozna wykonac " ++ (show stmt))
     return undefined
   Semicolon -> do
     return ()

-- instrukcje to tak jakby wskazowki
zinterpretuj_blok :: Block -> Przetwarzacz ()
zinterpretuj_blok (JustBlock wskazowki) = do
  mapM_ zinterpretuj_stmt_jesli_nie_ret wskazowki

zinterpretuj_podprogram :: Body -> Przetwarzacz ()
zinterpretuj_podprogram (JustBody defy stmt) = do
  srod <- lancuch_reader oblicz_def (map odpakuj_ConstOrVar defy)
  local (const srod) (mapM_ zinterpretuj_stmt_jesli_nie_ret stmt)

wloz_def :: Ident -> (TypQCL) -> Przetwarzacz (Sr.Srodowisko Loc)
wloz_def ident wartosc = do
  [lokacja] <- gets $ St.daj_wolne_lok 1
  modify $ St.zajmij_wolne_lok [lokacja]
  modify $ St.dodaj_wartosci [lokacja] [wartosc]
  srod <- ask
  return $ Sr.zmien_srodowisko [ident] [lokacja] srod

oblicz_def :: Def -> Przetwarzacz (Sr.Srodowisko Loc)
oblicz_def def = do
  case def of
   DefConstDef (ClassicalConstDef ident expr) -> do
     ile <- oblicz_wyrazenie expr
     wloz_def ident ile
   DefConstDef (QuantumConstDef typ ident) -> do
     return undefined
   VarDefDef (JustVarDef typ ident) -> do
     case typ of
      (SimpleType TString) -> do
        wloz_def ident (pak "")
      (SimpleType TBoolean) -> do
        wloz_def ident (pak False)
      (SimpleType TInt) -> do
        wloz_def ident ((pak :: Integer -> TypQCL) 0)
      (SimpleType TComplex) -> do
        wloz_def ident ((pak :: Complex Double -> TypQCL) $ (:+) 0 0)
      _ -> undefined
   VarDefDef (VarDefAss typ ident expr) -> do
     ile <- oblicz_wyrazenie expr
     wloz_def ident ile
   VarDefDef (VarDefTable typ ident expr) -> do
     PT (Calkowita ile) <- oblicz_wyrazenie expr
     return undefined
   FunDef _typ_wyniku ident argy cialo_fun -> do
     [lokacja] <- gets $ St.daj_wolne_lok 1
     modify $ St.zajmij_wolne_lok [lokacja]
     srod <- ask
     let srod' = Sr.zmien_srodowisko [ident] [lokacja] srod in do
       modify $ St.dodaj_podprogram lokacja
         (St.Podpr { St.arg_ident = [identyf | JustArgDef _ identyf <- argy],
                     St.srod = srod',
                     St.cialo = cialo_fun})
       return srod'
   ProcDef ident argy cialo -> do
     oblicz_def (FunDef undefined ident argy cialo)
   OperatorDef ident argy cialo -> do
     return undefined
   QufunctOperatorDef ident argy cialo -> do
     return undefined
   CondOperatorDef ident argy cialo -> do
     return undefined
   QufunctDef ident argy cialo -> do
     return undefined
   CondQufunctDef ident argy cialo -> do
     return undefined
   ExternOpDef ident argy -> do
     return undefined
   ExternQufunctDef ident argy -> do
     return undefined
   ExternCondOpDef ident argy -> do
     return undefined
   ExternCondQufunctDef ident argy -> do
     return undefined
