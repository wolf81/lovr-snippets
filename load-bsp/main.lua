io.stdout:setvbuf('no')

-- Create a new status channel
local channel = lovr.thread.getChannel('status')

-- Create a new thread called 'thread'
local thread = lovr.thread.newThread('bsp_loader.lua')

local drawables = {}

function lovr.load()
    -- Start the thread
    thread:start('e1m1.bsp')
end

function lovr.update(dt)
    -- Read and delete the message
    if channel:peek() then
        bsp = channel:pop(true)

        if type(bsp) == 'table' then
            print('generate meshes')

            for _, geometry in ipairs(bsp.geometry) do
                local material = lovr.graphics.newMaterial({
                    texture = geometry.image,
                })

                local vertices = {}

                for _, vertex in ipairs(geometry.vertices) do
                    table.insert(vertices, {
                        vertex.position:unpack(),
                        vertex.normal:unpack(),
                        vertex.uv:unpack(),
                    })
                end

                table.insert(drawables, {
                    mesh = lovr.graphics.newMesh(vertices),
                    material = material,
                })
            end
        end
    end
end

function lovr.draw(pass)
    for _, drawable in ipairs(drawables) do
        pass:setMaterial(drawable.material)
        pass:mesh(drawable.mesh)
    end
end
