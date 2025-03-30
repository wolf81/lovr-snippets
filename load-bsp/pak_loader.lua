local args = {...}
local filename = args[1]

local lovr = { 
    data = require 'lovr.data',
    thread = require 'lovr.thread',
    filesystem = require 'lovr.filesystem',
}

local ffi = require 'ffi'

-- Create a new status channel
local channel = lovr.thread.getChannel('status')
channel:push(filename)

-- Define C-style structures for reading binary data efficiently
ffi.cdef[[
    typedef struct {
        char name[56];   // File path (null-terminated if shorter)
        int32_t offset;  // Offset of file data
        int32_t length;  // Length of file data
    } entry_t;

    typedef struct {
        char signature[4]; // "PACK"
        int32_t dir_offset; // Offset to directory
        int32_t dir_length; // Length of directory (in bytes)
    } header_t;
]]

local function readPak(filename)
    local file = io.open(filename, 'rb')
    if not file then error('Failed to open PAK file: ' .. filename) end

    -- Read header
    local header = ffi.new('header_t')
    file:read(ffi.sizeof(header))
    file:seek('set', 0)  -- Reset position for direct read
    ffi.copy(header, file:read(ffi.sizeof(header)), ffi.sizeof(header))

    -- Verify signature
    if ffi.string(header.signature, 4) ~= 'PACK' then
        error('Invalid PAK file: Bad signature')
    end

    -- Read directory entries
    local num_entries = header.dir_length / ffi.sizeof('entry_t')
    file:seek('set', header.dir_offset)
    
    local entries = {}
    for i = 1, num_entries do
        local entry = ffi.new('entry_t')
        ffi.copy(entry, file:read(ffi.sizeof(entry)), ffi.sizeof(entry))
        entries[i] = {
            name = ffi.string(entry.name, 56):match('[^%z]+'), -- Remove null bytes
            offset = entry.offset,
            length = entry.length
        }
    end

    file:close()
    return { header = header, entries = entries }
end

-- Usage Example
local pak = readPak(filename)
for _, entry in ipairs(pak.entries) do
    print(string.format("File: %s, Offset: %d, Size: %d", entry.name, entry.offset, entry.length))
end
