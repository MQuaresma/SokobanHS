{-|Module : Main
Descrição : Jogo Sokoban escrito em Haskel
Copyright : Miguel Quaresma <miguelquaresma97@gmail.com>
            João Nogueira   <joaonogueira097@hotmail.com> 

Módulo responsável pela implementação do jogo em si, e pelo desenvolvimento da interface do mesmo.
-}

module Main where

import System.Directory 
import Data.Char
import Graphics.Gloss 
import Graphics.Gloss.Data.Picture 
import Graphics.Gloss.Interface.Pure.Game 


type Coordenadas = (Float, Float)

-- | Estado do jogo:
--
-- * Dimensões do mapa
-- * Coordenadas da boneco no mapa
-- * Coordenadas das caixas
-- * Coordenadas das paredes
-- * Coordenadas das posições finais das caixas
-- * Nro de moves
-- * Imagem da boneco
-- * Imagem da caixa
-- * Imagem da parede
-- * Imagem do local de arrumação das caixas
-- * Indicador do estado do mapa
-- * Background do nro de movimentos
-- * Imagem de congratulação
type GameStatus = ((Float,Float),Coordenadas,[Coordenadas], [Coordenadas], [Coordenadas], (Int, String), Picture, Picture, Picture, Picture, String, Picture)

assets_prefix="../assets/"

main :: IO ()
main = do 
        putStrLn "Escolha um boneco (homer/marge/lisa/bart): "
        escolha <- getLine --permite ao utilizador escolher o boneco que deseja
        putStrLn "Escolha um mapa (mapa1/mapa2/mapa3): "
        mapa <- getLine --permite ao utilziador escolher o mapa que deseja
        boneco <- loadBMP (assets_prefix ++ "game/" ++ escolha ++ ".bmp") -- carrega a imagem da boneco
        caixa <- loadBMP (assets_prefix ++ "game/" ++ escolha ++ "Crate.bmp") -- carega a imagem das caixas
        ficheiroMapa <- readFile (assets_prefix ++ "maps/" ++ mapa ++ ".txt") -- carega o ficheiro que contem o mapa
        parede <- loadBMP "../assets/game/paredeF.bmp" -- carega a imagem das paredes
        caixasF <- loadBMP "../assets/game/dot.bmp" -- carega a imagem das posições finais das caixas
        fim <- loadBMP "../assets/game/theEnd.bmp" -- carega a imagem de congratulação após o fim do jogo
        gameManager boneco caixa parede caixasF "Incompleto" "Movimentos: " ficheiroMapa fim
            


-- | Função encarregue de iniciar o jogo
gameManager :: Picture -> Picture -> Picture -> Picture -> String -> String -> String -> Picture -> IO()
gameManager boneco caixa parede caixasF estadoMp score mapaF fim = joga mapaInit desenhaMapa (reageManager mapaInit [mapaInit])
    where
        dim = ((fromIntegral (length h)) * 40+20 , (fromIntegral(length tabuleiro)) * 40+20)
        (h:t) = tabuleiro 
        (tabuleiro, coords) = dividemapa (inStr mapaF)
        ((x1,x2):xs) = map (\(x,y) -> (fromIntegral x, fromIntegral y)) (processacoordenadas (removeInv coords)) --coordenadas fornecidas no ficheiro de texto
        coordsCaixas = map (\(x,y) -> (x*40, y*40)) (map (\(x,y)->(x+1, y+1)) xs) --coordenadas das caixas
        tabuleiroSimples = reverse (tarefa2 (inStr mapaF)) --mapa simplificado
        coordsParedes = map (\(x,y) -> (x*40, y*40)) (recolheParedes tabuleiroSimples 1) --coordenadas dos locais de colocação das paredes
        coordsF =  map (\(x,y) -> (x*40, y*40)) (recolhePosF tabuleiroSimples 1) --coordenadas do local de arrumação das caixas
        mapaInit = (dim ,((x1+1) *40, (x2+1) *40), coordsCaixas , coordsParedes, coordsF, (0, score), boneco, caixa, parede, caixasF, estadoMp, fim) --estado inicial do mapa


-- | Função que cria um jogo.
joga :: mundo -> (mundo -> Picture) -> (Event -> mundo -> mundo) -> IO ()
joga mapaInicial desenha reage = play
    (InWindow "Sokoban" (1280, 720) (0, 0)) -- Tamanho da janela do jogo
    (white) -- Côr do fundo da janela
    45 -- refresh rate
    mapaInicial -- mapa inicial
    desenha -- função que desenha o mapa
    reage  -- função que reage a um evento (carregar numa tecla, mover o rato, etc)
    reageTempo -- função que reage ao passar do tempo 

-- | Desenha o jogo dentro da janela
desenhaMapa :: GameStatus -> Picture
desenhaMapa ((xMapa,yMapa),(x,y), coordsCaixas, coordsParedes, coordsF, (moves, score), boneco, caixa, paredes, caixasF, estadoMp, fim) | listaFinal coordsCaixas coordsF = Pictures [borda, tabuleiro, final] 
                                                                                                                                        | otherwise = Pictures [borda,tabuleiro, Pictures(colocaPosF coordsF caixasF), figura, Pictures(colocaCaixas coordsCaixas caixa), Pictures(colocaParedes coordsParedes paredes), estadoMap, pontos]
    where
    -- borda do mapa a preto, centrada na janela
    borda = Translate (-(xMapa+20)/2) (-(yMapa+20)/2) $ Color white (Polygon [(0,0),(0,yMapa + 20),(xMapa + 20,yMapa + 20),(xMapa + 20,0)])
    -- mapa a branco, centrado na janela
    tabuleiro = Translate (-xMapa/2) (-yMapa/2) $ Color white (Polygon [(0,0),(0,yMapa),(xMapa,yMapa),(xMapa,0)])
    -- * boneco dentro do mapa do jogo
    figura = Translate (-xMapa/2) (-yMapa/2) $ Translate x y boneco
    -- * coloca a caixa no local correto
    colocaCaixas :: [(Float, Float)] -> Picture -> [Picture]
    colocaCaixas [] _ = []
    colocaCaixas (h:t) caixa = (objeto h  caixa) : colocaCaixas t caixa
    objeto :: (Float, Float) -> Picture -> Picture
    objeto (x1,y1) caixa =  Translate (-xMapa/2) (-yMapa/2) $ Translate x1 y1 caixa
    -- * coloca as paredes
    colocaParedes :: [(Float, Float)] -> Picture -> [Picture]
    colocaParedes [] _ = []
    colocaParedes (h:t) parede = (objeto h  parede) : colocaParedes t parede
    -- * coloca o local onde devem ser colocadas as caixas
    colocaPosF :: [(Float, Float)] -> Picture -> [Picture]
    colocaPosF [] _ = []
    colocaPosF (h:t) pos = (objeto h  pos) : colocaPosF t pos
    (p1, p2) = unzip coordsParedes --devolve uma lista com as abcissas e outra com as ordenadas
    (cH, cV) = (maximum p1, maximum p2) --devovle o a maior abicssa e a maior ordenada das caixas
    estadoMap = Color black $ objeto (cH, cV + 100) $ Scale 0.25 0.25 $ Text estadoMp
    pontos = Color black $ objeto (cH,cV + 50) $ Scale 0.25 0.25 $ Text (score ++ (show moves))
    --imagem de fim do jogo
    final = objeto (xMapa/2,yMapa/2) fim
        


{--- | Lê os scores obtidos
processaScores :: [String] -> [Int]
processaScores [] = []
processaScores (h:t) = (read h) : processaScores t-}

-- | Reage a diversos eventos
reageManager :: GameStatus -> [GameStatus] -> Event -> GameStatus -> GameStatus
reageManager mapaInit _ (EventKey (Char 'r') Up _ _) mapa = mapaInit --reinicia o mapa caso o utilizador pressiona a tecla r
--reageManager _ (h:t) (EventKey (Char 'a') Up _ _) mapa = h --TODO: retroceder movimentos
reageManager mapaInit _ tecla mapa = reageEvento tecla mapa 




-- | Move a boneco uma coordenada para o lado
moveBoneco :: (Float,Float) -> GameStatus -> GameStatus
moveBoneco (x,y) mapa | listaFinal coordsCaixas coordsF = fim
                      | otherwise = continua
    where
    ((xMapa,yMapa),(xBoneco,yBoneco),coordsCaixas, coordsParedes, coordsF, (moves, score), boneco, caixa, paredes, caixasF, estadoMp, fimP) = mapa
    arredonda limite p = max 40 (min p (limite-40))
    fim = ((xMapa,yMapa),(arredonda xMapa (x + xBoneco),arredonda yMapa (y + yBoneco)),coordsCaixas, coordsParedes, coordsF, (moves, score), boneco, caixa, paredes, caixasF, "Completo", fimP) 
    continua = ((xMapa,yMapa),(arredonda xMapa (x + xBoneco),arredonda yMapa (y + yBoneco)),coordsCaixas, coordsParedes, coordsF, (moves, score), boneco, caixa, paredes, caixasF, estadoMp, fimP)



-- | Reage ao pressionar das setas do teclado, movendo a bola 5 pixéis numa direção
reageEvento :: Event -> GameStatus -> GameStatus
reageEvento (EventKey (SpecialKey KeyUp)    Down _ _) mapa  |testa = if(elem movimento coordsCaixas) then moveBoneco (0,40) mapaNovo else  moveBoneco (0,40)  mapaMv  
                                                            |otherwise = mapa
    where
        (limitesMp, posB, coordsCaixas, coordsParedes, coordsF, (moves, score), boneco, caixa, parede, caixasF, estadoMp, fimP) = mapa
        movimento = move posB 'U'
        testa = movimentoValido 'U' posB coordsCaixas coordsParedes
        coordsNovas = devolveNovo movimento 'U' coordsCaixas
        mapaNovo = (limitesMp, posB, coordsNovas, coordsParedes, coordsF, (moves+1, score), boneco, caixa, parede, caixasF, estadoMp, fimP)
        mapaMv = (limitesMp, posB, coordsCaixas, coordsParedes, coordsF, (moves+1, score),boneco, caixa, parede, caixasF, estadoMp, fimP)

reageEvento (EventKey (SpecialKey KeyDown)  Down _ _) mapa   |testa = if(elem movimento coordsCaixas) then moveBoneco (0,-40) mapaNovo else  moveBoneco (0,-40)  mapaMv  
                                                             |otherwise = mapa
    where
        (limitesMp, posB, coordsCaixas, coordsParedes, coordsF, (moves, score), boneco, caixa, parede, caixasF, estadoMp, fimP) = mapa
        movimento = move posB 'D'
        testa = movimentoValido 'D' posB coordsCaixas coordsParedes
        coordsNovas = devolveNovo movimento 'D' coordsCaixas
        mapaNovo = (limitesMp, posB, coordsNovas, coordsParedes, coordsF, (moves+1, score), boneco, caixa, parede, caixasF, estadoMp, fimP)
        mapaMv = (limitesMp, posB, coordsCaixas, coordsParedes, coordsF, (moves+1, score),boneco, caixa, parede, caixasF, estadoMp, fimP)

reageEvento (EventKey (SpecialKey KeyLeft)  Down _ _) mapa  |testa = if(elem movimento coordsCaixas) then moveBoneco (-40, 0) mapaNovo else  moveBoneco (-40, 0)  mapaMv  
                                                            |otherwise = mapa
    where
        (limitesMp, posB, coordsCaixas, coordsParedes, coordsF, (moves, score), boneco, caixa, parede, caixasF, estadoMp, fimP) = mapa
        movimento = move posB 'L'
        testa = movimentoValido 'L' posB coordsCaixas coordsParedes
        coordsNovas = devolveNovo movimento 'L' coordsCaixas
        mapaNovo = (limitesMp, posB, coordsNovas, coordsParedes, coordsF, (moves+1, score), boneco, caixa, parede, caixasF, estadoMp, fimP)
        mapaMv = (limitesMp, posB, coordsCaixas, coordsParedes, coordsF, (moves+1, score),boneco, caixa, parede, caixasF, estadoMp, fimP)

reageEvento (EventKey (SpecialKey KeyRight) Down _ _) mapa  |testa = if(elem movimento coordsCaixas) then moveBoneco (40, 0) mapaNovo else  moveBoneco (40, 0)  mapaMv  
                                                            |otherwise = mapa
    where
        (limitesMp, posB, coordsCaixas, coordsParedes, coordsF, (moves, score), boneco, caixa, parede, caixasF, estadoMp, fimP)= mapa
        movimento = move posB 'R'
        testa = movimentoValido 'R' posB coordsCaixas coordsParedes
        coordsNovas = devolveNovo movimento 'R' coordsCaixas
        mapaNovo = (limitesMp, posB, coordsNovas, coordsParedes, coordsF, (moves+1, score), boneco, caixa, parede, caixasF, estadoMp, fimP)
        mapaMv = (limitesMp, posB, coordsCaixas, coordsParedes, coordsF, (moves+1, score),boneco, caixa, parede, caixasF, estadoMp, fimP)

reageEvento _ mapa = mapa -- ignora qualquer outro evento


-- | Não reage ao passar do tempo.
reageTempo :: Float -> mundo -> mundo
reageTempo t m = m


-- | Devolve as coords de um determinado um objeto após se movimentar
move :: (Float,Float) -> Char -> (Float, Float)
move (l1, l2) c |c == 'U' = (l1 , l2 + 40)
                |c == 'D' = (l1 , l2 - 40)
                |c == 'L' = (l1 - 40  , l2)
                |c == 'R' = (l1 + 40  , l2)

-- | Verifica se o boneco se pode mover na direção desejada
movimentoValido :: Char -> (Float, Float) -> [Coordenadas] -> [Coordenadas] -> Bool
movimentoValido c coordsBoneco coordsCaixas coordsParedes | elem (nextMove) coordsParedes = False
                                                          | elem (nextMove) coordsCaixas && elem (move nextMove c) coordsCaixas = False 
                                                          | elem (nextMove) coordsCaixas && elem (move nextMove c) coordsParedes = False
                                                          | elem (nextMove) coordsCaixas = True
                                                          | otherwise = True
    where
        nextMove = move coordsBoneco c




-- | Recolhe as posições dos cardinais/paredes do mapa
recolheParedes :: [String] -> Float -> [Coordenadas]
recolheParedes [] _ = []
recolheParedes (h:t) n = recolheLinha h n 1 ++ recolheParedes t (n+1)
    where
        recolheLinha :: String -> Float -> Float -> [Coordenadas]
        recolheLinha [] _ _  = []
        recolheLinha (h:t) linha col | h == '#' = (col, linha) : recolheLinha t linha (col + 1)
                                     |otherwise = recolheLinha t linha (col + 1)

-- | Recolhe as posições das caixas do mapa
recolhePosF :: [String] -> Float -> [Coordenadas]
recolhePosF [] _ = []
recolhePosF (h:t) n = recolheLinha h n 1 ++ recolhePosF t (n+1)
    where
        recolheLinha :: String -> Float -> Float -> [Coordenadas]
        recolheLinha [] _ _  = []
        recolheLinha (h:t) linha col | h == '.' || h == 'I' = (col, linha) : recolheLinha t linha (col + 1)
                                     |otherwise = recolheLinha t linha (col + 1)

-- | Devolve a lista de coords das caixas com as suas novas posições
devolveNovo :: Coordenadas -> Char -> [Coordenadas] -> [Coordenadas]
devolveNovo cords c (x:xs) |cords == x = (novaCoord : xs)
                           |otherwise = x : (devolveNovo cords c xs)
    where
        novaCoord = move cords c 

-- | Verifica se todas as caixas estão na posição final 
listaFinal :: [Coordenadas] -> [Coordenadas] -> Bool
listaFinal [] [] = True
listaFinal _ [] = False
listaFinal (h:t) final |elem h final = listaFinal t (filter (/= h) final)
                       |otherwise = False 


-- | Funções da Tarefa 2
tarefa2 :: [String] -> [String]
tarefa2 linhas = colocaTudo (reverse (simplificaMapa (reverse tab) todas (reverse tab))) coordenadasF 
    where
        (tab, coordenadas) = dividemapa linhas
        coordenadasF = processacoordenadas (removeInv coordenadas) 
        todas = recolheCords 0 0 tab

-- | Remove os cardinais redundantes do mapa inteiro
simplificaMapa :: [String] -> [(Int, Int)] -> [String] -> [String]
simplificaMapa [] _ _ = []
simplificaMapa (h:t) cds tab = removeDeLinha h cds tab : simplificaMapa t (drop (length h) cds) tab


-- | Remove os cardinais redundates de cada linha, verificando, caso o caracter em questão seja um cardinal, todos os caracteres à sua volta e atuando em conformidade
removeDeLinha :: String-> [(Int, Int)]-> [String] -> String
removeDeLinha [] _ _ = []
removeDeLinha (h:t) (x:xs) tab |devolveCarater x tab == ' ' = ' ' : removeDeLinha t xs tab
                               |devolveCarater x tab == '.' = '.' : removeDeLinha t xs tab
                               |(devolveCarater (l1, l2 + 1) tab == ' ' || devolveCarater (l1 + 1, l2) tab == ' ' || devolveCarater (l1, l2 - 1) tab == ' ' || devolveCarater (l1 - 1, l2) tab == ' ' || devolveCarater (l1 + 1, l2 + 1) tab == ' ' || devolveCarater (l1 - 1, l2 - 1) tab == ' ' || devolveCarater (l1 - 1, l2 + 1) tab == ' ' || devolveCarater (l1 + 1, l2 - 1) tab == ' ') = '#' :  removeDeLinha t xs tab
                               |(devolveCarater (l1, l2 + 1) tab == '.' || devolveCarater (l1 + 1, l2) tab == '.' || devolveCarater (l1, l2 - 1) tab == '.' || devolveCarater (l1 - 1, l2) tab == '.' || devolveCarater (l1 + 1, l2 + 1) tab == '.' || devolveCarater (l1 - 1, l2 - 1) tab == '.' || devolveCarater (l1 - 1, l2 + 1) tab == '.' || devolveCarater (l1 + 1, l2 - 1) tab == '.') = '#' :  removeDeLinha t xs tab
                               |(devolveCarater (l1, l2 + 1) tab == '#' && devolveCarater (l1 + 1, l2) tab == '#' && devolveCarater (l1, l2 - 1) tab == '#' && devolveCarater (l1 - 1, l2) tab == '#' && devolveCarater (l1 + 1, l2 + 1) tab == '#' && devolveCarater (l1 - 1, l2 - 1) tab == '#' && devolveCarater (l1 - 1, l2 + 1) tab == '#' && devolveCarater (l1 + 1, l2 - 1) tab == '#') = ' ' :  removeDeLinha t xs tab
    where
        (l1, l2) = x


-- | Devolve o carater correspondente a um par de coordenadas
devolveCarater :: (Int, Int) -> [String] -> Char
devolveCarater crd mp = percorreLinhas mp crd 0
    where
        percorreLinhas :: [String] -> (Int,Int) -> Int -> Char
        percorreLinhas [] _ n = '#'
        percorreLinhas (h:t) (p1, p2) n |p2 == n = percorreColunas h p1 0
                                        |otherwise = percorreLinhas t (p1, p2) (n+1)
        
        percorreColunas :: String -> Int -> Int -> Char
        percorreColunas [] _ n = '#'
        percorreColunas (x:xs) p1 n |p1 == n = x 
                                    |otherwise = percorreColunas xs p1 (n+1)


-- | Recolhe todas as coordenadas referentes a todas posições possíveis no mapa para facilitar a remoção dos cardinais                    
recolheCords :: Int -> Int -> [String] -> [(Int, Int)]
recolheCords _ _ [] = []
recolheCords c l (x:xs) = (aux c l x) ++ recolheCords c (l+1) xs
    where
        aux :: Int -> Int -> String -> [(Int, Int)]
        aux c l  [] = []
        aux c l (h:t) = (c, l) : aux (c+1) l t

-- | Coloca o boneco e as caixas no mapa
colocaTudo :: [String] -> [(Int, Int)] -> [String]
colocaTudo l (h:t) = colocaBoneco (colocaCaixas l t) h


-- | Coloca o boneco no mapa
colocaBoneco :: [String] -> (Int,Int) -> [String]
colocaBoneco l (x,y) = reverse (percorreLinhas (reverse l) (x,y)) 
    where
        percorreLinhas :: [String] -> (Int, Int) -> [String]
        percorreLinhas (h:t) (p1, p2) |p2 == 0 = (percorreColunas h  p1) : t 
                                      |otherwise = h : percorreLinhas t (p1, p2 - 1) 

        percorreColunas :: String -> Int -> String
        percorreColunas [] _ = []
        percorreColunas (z:zs) n |n == 0 = 'o' : zs 
                                 |otherwise = z : percorreColunas zs (n-1)


-- | Chama a função __colocaCaixa__ para colocar todas as caixas no mapa
colocaCaixas :: [String] -> [(Int, Int)] -> [String]
colocaCaixas l [z] = colocaCaixa l z 
colocaCaixas l (h:t) = colocaCaixas (colocaCaixa l h) t 


-- | Coloca uma caixa no mapa
colocaCaixa :: [String] -> (Int,Int) -> [String]
colocaCaixa l (x,y) = reverse (percorreLinhas (reverse l) (x,y)) 
    where
        percorreLinhas :: [String] -> (Int, Int) -> [String]
        percorreLinhas (h:t) (p1, p2) | p2 == 0 = (percorreColunas h  p1) : t 
                                      |otherwise = h : percorreLinhas t (p1, p2 - 1) 

        percorreColunas :: String -> Int -> String
        percorreColunas [] _ = []
        percorreColunas (z:zs) n |n == 0 = if(z == '.') then 'I' : zs else 'H' : zs 
                                 |otherwise = z : percorreColunas zs (n-1)


-- | Funções Gerais


-- | Divide o ficheiro em duas partes a primeira contendo o mapa e a segunda as coordenadas
dividemapa :: [String] -> ([String], [String]) 
dividemapa [] = ([], [])
dividemapa l = splitAt (aux l) l
    where 
        aux :: [String] -> Int
        aux [] = 0
        aux (x:xs) = if(isWall x) then 1 + aux xs else 0  
        
        isWall :: String -> Bool
        isWall [] = False
        isWall (x:xs) = (ord x == 35) || isWall xs


-- | Converte a lista de coordenadas, ainda em lista de /strings/, numa lista de pares de /Int/s 
processacoordenadas :: [String] -> [(Int, Int)]
processacoordenadas [] = []
processacoordenadas (h:t) = (read x, read y) : processacoordenadas t 
        where
            [x, y] = words h


-- |Remove a coordenadas inválidas (com um so nro; com caracteres que não são nros ou linhas vazias)
removeInv :: [String] -> [String]
removeInv [] = []
removeInv (x:xs) | x==""= removeInv xs
                 | length (words x) /= 2 = removeInv xs
                 | remaux x == False = removeInv xs
                 | otherwise = x : removeInv xs

remaux :: String -> Bool
remaux [] = True
remaux (h:t) = if isDigit h || h == ' ' then remaux t else False

inStr :: String -> [String]
inStr [] = []
inStr ['\n'] = [[],[]]
inStr (x:xs) = case x of
    '\n' -> []:inStr xs
    otherwise -> case inStr xs of
        y:ys -> (x:y):ys
        [] -> [[x]]
