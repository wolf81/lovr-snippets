local args = { ... }

local lovr = { thread = require 'lovr.thread' }
local channel = lovr.thread.getChannel('test')
local x = args[1]

while true do
  x = x + 1
  channel:push(x)
end
