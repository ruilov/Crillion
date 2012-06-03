Tile = class()

function Tile:init(x,y,color)
    self.x = x
    self.y = y
    self.color = color
    self.dead = false
    self.star = false
    self.movable = false
end

function Tile:draw()
    pushStyle()
    strokeWidth(1)
    fill(self.color)
    rect((self.x-1/2)*tileSize,(self.y-1/2)*tileSize,tileSize,tileSize)
    
    if self.star then
        fill(247, 247, 247, 255)
        ellipse(self.x*tileSize,self.y*tileSize,tileSize/2,tileSize/2)
    end
    
    if self.movable then
        fill(255, 255, 255, 255)
        rect((self.x-.1)*tileSize,(self.y-.4)*tileSize,tileSize*.2,tileSize*.8)
    end
    
    if self.dead then
        fill(0, 0, 0, 255)
        rect((self.x-.2)*tileSize,(self.y-.2)*tileSize,tileSize*.4,tileSize*.4)
    end
    popStyle()
end
