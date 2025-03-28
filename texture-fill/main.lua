local texture = lovr.graphics.newTexture('morning_sky.jpg')

function lovr.draw(pass)
    pass:fill(texture)
end
