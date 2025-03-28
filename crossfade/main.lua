local textures = {}
local time = 0
local blend = 0

local vertex = [[
    vec4 lovrmain() {
        return DefaultPosition;
    }
]]

local fragment = [[
    uniform texture2D texture1;
    uniform texture2D texture2;
    uniform float blend;

    vec4 lovrmain() {
        vec4 c1 = getPixel(texture1, UV);
        vec4 c2 = getPixel(texture2, UV);
        return mix(c1, c2, blend);
    }
]]

local shader = lovr.graphics.newShader(vertex, fragment)

local vertices = {
    { -1.0,  1.0 ; 0.0, 0.0 },
    {  1.0,  1.0 ; 1.0, 0.0 },
    { -1.0, -1.0 ; 0.0, 1.0 },

    { -1.0, -1.0 ; 0.0, 1.0 },
    {  1.0,  1.0 ; 1.0, 0.0 },
    {  1.0, -1.0 ; 1.0, 1.0 },
}

local mesh = lovr.graphics.newMesh({
  { name = 'VertexPosition', type = 'vec2' },
  { name = 'VertexUV', type = 'vec2' }
}, vertices)

function lovr.load(args)
    textures[#textures + 1] = lovr.graphics.newTexture('morning_sky.jpg')
    textures[#textures + 1] = lovr.graphics.newTexture('evening_sky.jpg')
end

function lovr.update(dt)
    time = time + dt
    blend = math.abs(math.sin(time))
end

function lovr.draw(pass)
    pass:setShader(shader)
    pass:setClear(0.5, 0.5, 0.5, 1.0)
    pass:send('texture1', textures[1])
    pass:send('texture2', textures[2])
    pass:send('blend', blend)
    pass:draw(mesh, 0, 1.7, -1)
    pass:setShader()
end
