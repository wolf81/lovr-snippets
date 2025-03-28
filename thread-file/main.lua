-- Create a new test channel
local channel = lovr.thread.getChannel('test')

-- Create a new thread called 'thread' using the thread.lua file
local thread = lovr.thread.newThread('thread.lua')

function lovr.load()
    -- Start the thread
    thread:start(100)
end

function lovr.update(dt)
    -- Read and delete the message
    message = channel:pop()
end

function lovr.draw(pass)
    -- Display the message on screen/headset
    pass:text(tostring(message), 0, 1.7, -5)
end
