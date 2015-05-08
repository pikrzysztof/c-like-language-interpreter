all:
#	happy -gcai Pargramatyka.y
#	alex -g Lexgramatyka.x
	ghc --make Testgramatyka.hs -o Testgramatyka

clean:
	-rm -f *.log *.aux *.hi *.o *.dvi
	-rm -f Docgramatyka.ps

distclean: clean
	-rm -f Docgramatyka.* Lexgramatyka.* Pargramatyka.* Layoutgramatyka.* Skelgramatyka.* Printgramatyka.* Testgramatyka.* Absgramatyka.* Testgramatyka ErrM.* SharedString.* ComposOp.* gramatyka.dtd XMLgramatyka.* Makefile*
