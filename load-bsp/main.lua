local Pak = require 'pak'

local meshes = {}
local textures = {}

function lovr.load()
    local pak = Pak('pak0.pak')

    -- TODO: add error handling
    pak:loadMap(function(bsp)
        print('generate textures')

        for _, tex_info in ipairs(bsp.textures) do
            table.insert(textures, lovr.graphics.newTexture(tex_info.image, {
                type = '2d',
                usage = { 'sample' },
                label = tex_info.name,
            }))
        end

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

            local texture = textures[geometry.texture_id]
            local mesh = lovr.graphics.newMesh(vertices)
            mesh:setMaterial(texture)

            table.insert(meshes, mesh)
        end

        for _, entity in ipairs(bsp.entities) do
            if entity.classname == 'info_player_start' then
                local x, y, z = entity.origin:match("(%-?%d+) (%-?%d+) (%-?%d+)")
                local angle = tonumber(entity.angle)

                -- TODO: set camera origin
            end
        end
    end)
end

function lovr.update(dt)

end

function lovr.draw(pass)
    -- pass:setShader('normal')
    -- pass:setWireframe(true)
    for i, mesh in ipairs(meshes) do
        pass:draw(mesh)
    end
end
