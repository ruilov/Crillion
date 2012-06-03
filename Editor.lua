function drawEditor()
    userInputEditor()
    
    background()
    noFill()
    stroke(255, 255, 255, 255)
    strokeWidth(wallThickness)
    rect(bottom.x-wallThickness,bottom.y-wallThickness,
        dims.x+2*wallThickness,dims.y+2*wallThickness)
    
    translate(bottom.x+dims.x/2,bottom.y+dims.y/2)
    
    map:draw()
    ball:draw()
    
    resetMatrix()
    translate(bottom.x+300,top.y+40)
    for t,v in pairs(editMap) do
        t:draw()
    end    
    
end

lastTouchT = 0
alreadyPrinted = false
function userInputEditor()
    if CurrentTouch.state ~= BEGAN and CurrentTouch.state ~= MOVING then return(0) end
    if ElapsedTime - lastTouchT < .05 then return(0) end
    
    lastTouchT = ElapsedTime
    
    if printMap ~= 0 then 
        if not alreadyPrinted then
            map:print(ball)
            alreadyPrinted = true
            return(0)
        end
    else alreadyPrinted = false
    end
    
    if CurrentTouch.x < bottom.x or CurrentTouch.x > top.x then return(0) end
    if CurrentTouch.y < bottom.y or CurrentTouch.y > top.y then return(0) end
     
    x = math.floor((CurrentTouch.x-bottom.x)/tileSize)-(gridW-1)/2
    y = math.floor((CurrentTouch.y-bottom.y)/tileSize)-(gridH-1)/2
    
    if moveBallOn == 1 then
        ball.x = x + .25
        ball.y = CurrentTouch.y-(bottom.y+top.y)/2
        return(0)
    end
    
    foundTile = false
    for tile,v in pairs(map.tiles) do
        if tile.x==x and tile.y==y then
            foundTile = true
            t = makeTile()
            t.x = x
            t.y = y
            map.tiles[tile] = nil
            if t.color ~= black then map.tiles[t] = true end
            break
        end
    end
    
    if not foundTile then
        t = makeTile()
        t.x = x
        t.y = y
        if t.color ~= black then map.tiles[t] = true end
    end
end

function makeTile()
    tile = Tile(0,0,nil)
    if tileColor == 0 then tile.color = black end
    if tileColor == 1 then tile.color = gray end
    if tileColor == 2 then tile.color = brown end
    if tileColor == 3 then tile.color = pink end
    if tileColor == 4 then tile.color = blue end
    if tileColor == 5 then tile.color = red end
    if tileColor == 6 then tile.color = green end
    if tileColor == 7 then tile.color = lightblue end
    if tileColor == 8 then tile.color = yellow end
    
    if tileType == 1 then tile.dead = true end
    if tileType == 2 then tile.star = true end
    if tileType == 3 then tile.movable = true end
    return(tile)
end
