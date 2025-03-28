-- Create a new status channel
local channel = lovr.thread.getChannel('status')

-- Create a new thread called 'thread'
local thread = lovr.thread.newThread('bsp_loader.lua')

function lovr.load()
    -- Start the thread
    thread:start('e1m1.bsp')
end

function lovr.update(dt)
    -- Read and delete the message
    if channel:peek() then
        message = channel:pop(true)

        if type(message) == 'table' then
            if message['type'] == 'image' then
                local data = message['data']
                local name = message['name']
                local png = data:encode('png')
                lovr.filesystem.write(name .. '.png', png)
                message = name
            end
        end
    end
end

function lovr.draw(pass)
    -- Display the message on screen/headset
    pass:text(tostring(message), 0, 1.7, -5)
end
