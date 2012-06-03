supportedOrientations(LANDSCAPE_ANY)

tileSize = 40
wallThickness = 15
gridW = 15
gridH = 11
dims = vec2(tileSize*gridW,tileSize*gridH)
bottom = vec2(80,150)
top = bottom+dims
ballRadius = tileSize/4
speedY = 4.2

map = nil
ball = nil
explosions = {}

gameState = "paused"
lastStateT = 0
mapIdx = 1
livesused = 0
    
function setup()
    initMapCode()   
    map = Map(mapIdx)
    ball = makeBall(mapIdx)
    editMap = makeTiles(editStr)
    
    -- editor
    watch("livesused")
    editor = 0
    iparameter("editor",0,1,0)
    --iparameter("tileColor",0,8,0)
    --iparameter("tileType",0,3,0)
    --iparameter("moveBallOn",0,1,0)
    --iparameter("printMap",0,1,0)
    print("touch screen to move")
end

function draw()
    if editor ~= 0 then drawEditor() else runGame() end
end

function runGame() 
    
    if gameState == "won" then
        if ElapsedTime - lastStateT < 2 then
            -- just wait
        else
            -- start new level
            gameState = "paused"
            lastStateT = ElapsedTime
            mapIdx = mapIdx%table.maxn(maps) +1
            map = Map(mapIdx)
            ball = makeBall(mapIdx)
        end
    elseif gameState == "paused" then
        -- just wait for user
        userInput()   
    elseif gameState == "game over" then  
        if ElapsedTime - lastStateT < 1 then
            -- just wait
        else
            gameState = "paused"
            lastStateT = ElapsedTime
            map = Map(mapIdx)
            ball = makeBall(mapIdx)
        end
    elseif gameState == "running" then
        -- update game state
        local userInputV = userInput()
    
        collidedTiles = moveBall(userInputV) 
        for tile,dir in pairs(collidedTiles) do
            if tile.dead then
                gameState = "game over"
                lastStateT = ElapsedTime
                livesused = livesused + 1
                sound(SOUND_SHOOT,2)
            elseif tile.star then
                -- ball changes color
                ball.color = tile.color
                sound(SOUND_BLIT,8)         
            elseif tile.color == ball.color then
                if tile.movable then 
                    if math.abs(dir) < 2 then 
                        newX = tile.x - dir
                        newY = tile.y
                    else 
                        newX = tile.x
                        newY = tile.y - dir/2 
                    end
                    
                    if math.abs(newX) < gridW /2 and math.abs(newY) < gridH /2 and
                        not map:hasXY(newX,newY) then
                        -- move tile
                        sound(SOUND_JUMP,40)
                        tile.x = newX
                        tile.y = newY
                    end
                else 
                    -- destroy tile
                    map.tiles[tile]=nil
                    table.insert(explosions,Explosion(tile.x,tile.y))
                    sound(SOUND_EXPLODE,55)
                end
            elseif tile.color == gray then
                -- hit wall
                sound(SOUND_BLIT,8)
            end
        end
            
        won = true
        for tile,v in pairs(map.tiles) do
            if not tile.dead and not tile.star and not tile.movable and
                tile.color ~= gray then 
                    won = false 
            end  
        end
        if won then
            print("you won",mapIdx)
            gameState = "won"
            lastStateT = ElapsedTime
            sound(SOUND_JUMP,13)
        end
    end
    
    for i,exp in ipairs(explosions) do
        keep = exp:advance()
        if not keep then table.remove(explosions,i) end
    end

    drawGame()   
end

function userInput() 
    if CurrentTouch.state == BEGAN or CurrentTouch.state == MOVING then
        if gameState =="running" and math.abs(CurrentTouch.x - top.x+10)<20 and
        math.abs(CurrentTouch.y-top.y-80)<20 then
            gameState = "game over"
            lastStateT = ElapsedTime-1
            livesused = livesused + 1
        elseif gameState == "running" and ElapsedTime - lastStateT > .2 then
            if CurrentTouch.x<WIDTH/2 then return(-1) else return(1) end   
        else 
            gameState = "running" 
            lastStateT = ElapsedTime
        end
    end
    return(0)
end

function drawGame()
    background()
    if gameState == "won" then
        c = math.floor((ElapsedTime-lastStateT)*127)
        fill(c,c,c,255)
    else 
        noFill()
    end
    stroke(255, 255, 255, 255)
    strokeWidth(wallThickness)
    rect(bottom.x-wallThickness,bottom.y-wallThickness,
        dims.x+2*wallThickness,dims.y+2*wallThickness)
    
    translate(bottom.x+dims.x/2,bottom.y+dims.y/2)

    map:draw() 
    ball:draw()
    
    for i,exp in ipairs(explosions) do
        exp:draw()
    end
    
    -- the reset button
    resetStyle()
    resetMatrix()
    strokeWidth(8)
    stroke(255, 255, 255, 255)
    noFill()
    ellipse(top.x-10,top.y+80,60,60)
    fill(0, 0, 0, 255)
    strokeWidth(0)
    rect(top.x-10,top.y+80,15,100)
    strokeWidth(8)
    lineCapMode(PROJECT)
    line(top.x+4,top.y+101,top.x-2,top.y+80)
    line(top.x+6,top.y+102,top.x+26,top.y+101)
end

-- 0 is no input, -1 is left and 1 is right
function moveBall(userInputY)
    speedX = math.abs(speedY)/tileSize
    if mapIdx == 12 then speedX = speedX / 1.1 end
    
    -- allow moving the target if the ball is almost there
    if math.abs(ball.targetX-ball.x) <= speedX then
        ball.targetX = ball.targetX + userInputY/2
    end
    
    if ball.targetX - ball.x < 0 then speedX = -speedX 
    elseif ball.targetX == ball.x then speedX = 0 end
    
    -- PHYSICS LOOP
    simT = 0
    speed = vec2(speedX / DeltaTime, speedY / DeltaTime)
    collidedTiles = {}
    lastTs = {}
    
    while simT < DeltaTime do
        -- calculate the next collision, including getting to the target
        minT = DeltaTime-simT
        newVec = vec2(speed.x,speed.y)
        newTargetX = ball.targetX
        thisTile = nil
        thisDir = 0
        
        -- hit the target?
        targetT = (ball.targetX - ball.x) / speed.x
        if targetT > 0 and targetT < minT then
            minT = targetT
            newVec = vec2(0,speed.y)
            newTargetX = ball.targetX
            thisTile = nil
        end
        
        -- hit the walls?
        topWallT = (dims.y/2-ballRadius-ball.y) / speed.y
        if (topWallT > 0 or (topWallT == 0 and speed.y > 0)) and topWallT < minT then
            minT = topWallT
            newVec = vec2(speed.x,-speed.y)
            newTargetX = ball.targetX
            thisTile = nil
        end
        bottomWallT = (-dims.y/2+ballRadius-ball.y) / speed.y
        if (bottomWallT > 0 or (bottomWallT == 0 and speed.y < 0)) and bottomWallT < minT then
            minT = bottomWallT
            newVec = vec2(speed.x,-speed.y)
            newTargetX = ball.targetX
            thisTile = nil
        end
        leftWallT = (-gridW/2+ballRadius/tileSize-ball.x) / speed.x
        if (leftWallT > 0 or (leftWallT == 0 and speed.x < 0)) and leftWallT < minT then
            minT = leftWallT
            newVec = vec2(-speed.x,speed.y)
            newTargetX = -gridW/2 + .75
            thisTile = nil
        end
        rightWallT = (gridW/2-ballRadius/tileSize-ball.x) / speed.x
        if (rightWallT > 0 or (rightWallT == 0 and speed.x > 0)) and rightWallT < minT then
            minT = rightWallT
            newVec = vec2(-speed.x,speed.y)
            newTargetX = gridW/2 - .75
            thisTile = nil
        end
        
        -- collide with tiles?
        for tile,v in pairs(map.tiles) do
            rightX = (tile.x+.5)+ballRadius/tileSize
            leftX = (tile.x-.5)-ballRadius/tileSize
            topY = (tile.y+.5)*tileSize+ballRadius
            bottomY = (tile.y-.5)*tileSize-ballRadius

            -- top wall
            topWallT = (topY-ball.y) / speed.y
            if (topWallT > 0 or (topWallT == 0 and speed.y < 0))
                and topWallT < minT then
                    -- check the x coord
                    ballXAtT = ball.x + speed.x * topWallT
                    if ballXAtT > leftX and ballXAtT < rightX then
                        minT = topWallT
                        newVec = vec2(speed.x,-speed.y)
                        newTargetX = ball.targetX
                        thisTile = tile
                        thisDir = 2
                    end
            end
            
            -- bottom wall
            bottomWallT = (bottomY-ball.y) / speed.y
            if (bottomWallT > 0 or (bottomWallT == 0 and speed.y > 0))
                and bottomWallT < minT then
                    -- check the x coord
                    ballXAtT = ball.x + speed.x * bottomWallT
                    if ballXAtT > leftX and ballXAtT < rightX then
                        minT = bottomWallT
                        newVec = vec2(speed.x,-speed.y)
                        newTargetX = ball.targetX
                        thisTile = tile
                        thisDir = -2
                    end
            end
            
            -- left wall
            leftWallT = (leftX-ball.x) / speed.x
            if (leftWallT > 0 or (leftWallT == 0 and speed.x > 0))
                and leftWallT < minT then
                    -- check the y coord
                    ballYAtT = ball.y + speed.y * leftWallT
                    if ballYAtT > bottomY and ballYAtT < topY then
                        minT = leftWallT
                        newVec = vec2(-speed.x,speed.y)
                        newTargetX = tile.x - 1.25
                        thisTile = tile
                        thisDir = -1
                    end
            end
            -- right wall
            rightWallT = (rightX-ball.x) / speed.x
            if (rightWallT > 0 or (rightWallT == 0 and speed.x < 0))
                and rightWallT < minT then
                    -- check the y coord
                    ballYAtT = ball.y + speed.y * rightWallT
                    if ballYAtT > bottomY and ballYAtT < topY then
                        minT = rightWallT
                        newVec = vec2(-speed.x,speed.y)
                        newTargetX = tile.x + 1.25
                        thisTile = tile
                        thisDir = 1
                    end
            end
        end
        
        -- advance minT
        simT = simT + minT
        ball.x = ball.x + speed.x * minT
        ball.y = ball.y + speed.y * minT
        ball.targetX = newTargetX
        speed = newVec
        
        if thisTile ~= nil then
            collidedTiles[thisTile] = thisDir
        end
        
        -- safety check
        if table.maxn(lastTs) > 10 then
            sum = 0
            for i,v in ipairs(lastTs) do sum = sum + v end
            if sum<=0 then
                print("loopong forever?")
                gameOver = true
                break
            end
            table.remove(lastTs,1)
         end  
         table.insert(lastTs,minT)
    end
    
    speedY = speed.y * DeltaTime
    
    return(collidedTiles)
end
