function lovr.load()
    threadCode = [[
        local lovr = { 
            thread = require 'lovr.thread',
            timer = require 'lovr.timer', 
        }

        -- Create channels for communication between threads
        local channel = {
            a = lovr.thread.getChannel('a'),
            b = lovr.thread.getChannel('b'),
        }

        local x = 0
        local running = true

        while true do
            if channel.b:peek() then
                channel.b:pop()
                running = (not running)
            end
            
            -- only update and push values if not paused
            if running then
                x = x + 1
                channel.a:push(x, true)    
            end    
        end
    ]]

    -- Create channels for communication between threads
    channel = {
        a = lovr.thread.getChannel('a'), -- from/to secondary thread
        b = lovr.thread.getChannel('b'), -- from/to main thread
    }

    -- Create a new thread called 'thread' using the code above
    thread = lovr.thread.newThread(threadCode)

    -- Start the thread
    thread:start()
end

function lovr.update(dt)
    if channel.a:peek() then
        message = channel.a:pop()
    end
end

function lovr.draw(pass)
    -- Display the message on screen/headset
    pass:text(tostring(message), 0, 1.7, -5)
end

function lovr.keyreleased(key, scancode)
    if key == 'space' then
        channel.b:push('toggle_pause')
    end
end
