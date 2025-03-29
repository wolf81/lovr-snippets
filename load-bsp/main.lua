-- Create a new status channel
local channel = lovr.thread.getChannel('status')

-- Create a new thread called 'thread'
local thread = lovr.thread.newThread('bsp_loader.lua')

local meshes = {}

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
                local vertices = {}            

                -- emulate GL_TRIANGLE_FAN
                for i = 2, #geometry.vertices - 1 do
                    vertex1 = geometry.vertices[1]
                    vertex2 = geometry.vertices[i]
                    vertex3 = geometry.vertices[i + 1]

                    for _, vertex in ipairs({vertex1, vertex2, vertex3}) do
                        local px, py, pz = vertex.position:unpack()
                        local nx, ny, nz = vertex.normal:unpack()
                        local ux, uy = vertex.uv:unpack()
                        table.insert(vertices, {
                            px, py, pz, nx, ny, nz, ux, uy
                        })
                    end
                end
                    
                local vertex1 = geometry.vertices[1]
                local vertex2 = geometry.vertices[#geometry.vertices]
                local vertex3 = geometry.vertices[2]

                for _, vertex in ipairs({vertex1, vertex2, vertex3}) do
                    local px, py, pz = vertex.position:unpack()
                    local nx, ny, nz = vertex.normal:unpack()
                    local ux, uy = vertex.uv:unpack()
                    table.insert(vertices, {
                        px, py, pz, nx, ny, nz, ux, uy
                    })
                end


                local mesh = lovr.graphics.newMesh(vertices)
                mesh:setMaterial(geometry.image)

                table.insert(meshes, mesh)
            end
        end
    end
end

function lovr.draw(pass)
    pass:setWireframe(true)
    for _, mesh in ipairs(meshes) do
        pass:draw(mesh)
    end
end
