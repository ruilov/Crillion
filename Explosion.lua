Explosion = class()

function Explosion:init(x,y)
    self.x = x
    self.y = y
    self.frame = 0
end

function Explosion:advance()
    self.frame = self.frame + 1
    return self.frame < 10
end

function Explosion:draw()
    pushStyle()
    strokeWidth(0)
    fill(131, 131, 131, 255)
    radius = tileSize/4 * self.frame/10 * 2
    ellipse((self.x-.25)*tileSize+10,(self.y-.25)*tileSize,radius,radius)
    ellipse((self.x+.25)*tileSize,(self.y-.25)*tileSize,radius,radius)
    ellipse((self.x-.25)*tileSize,(self.y+.25)*tileSize-5,radius,radius)
    ellipse((self.x+.25)*tileSize,(self.y+.25)*tileSize,radius,radius)
end
