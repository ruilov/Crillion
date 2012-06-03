Ball = class()

function Ball:init(x,y,color)
    -- you can accept and set parameters here
    self.x = x
    self.y = y
    self.targetX = x
    self.color = color
end

function Ball:draw()
    fill(self.color)
    noClip()
    ellipseMode(RADIUS)
    noStroke()
    ellipse(self.x*tileSize,self.y,ballRadius,ballRadius)
end
