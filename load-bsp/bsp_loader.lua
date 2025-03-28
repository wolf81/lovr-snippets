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
        int32_t offset;
        int32_t length; 
    } lump_t;

    typedef struct {
        int32_t version;
        lump_t entities;
        lump_t planes;
        lump_t miptex;
        lump_t vertices;
        lump_t visilist;
        lump_t nodes;
        lump_t texinfo;
        lump_t faces;
        lump_t lightmaps;
        lump_t clipnodes;
        lump_t leafs;
        lump_t lface;
        lump_t edges;
        lump_t ledges;
        lump_t models;
    } header_t;

    typedef struct {
        float x, y, z;
    } vec3_t;

    typedef struct {
        vec3_t min;
        vec3_t max;
    } boundbox_t;

    typedef struct { 
        vec3_t position;
        vec3_t tex_coord;
        vec3_t normal;
    } vertex_t;

    typedef struct {
        uint16_t vertex0;
        uint16_t vertex1;
    } edge_t;

    typedef struct {
        vec3_t normal;
        float distance;
        int32_t type;
    } plane_t;

    typedef struct {
        int16_t plane_id;

        int16_t side;
        int32_t ledge_id;
        int16_t ledge_num;

        int16_t texinfo_id;
        uint8_t typelight;
        uint8_t baselight;
        uint8_t light[2];
        int32_t lightmap;
    } face_t;

    typedef struct {
        boundbox_t bound;
        vec3_t origin;
        uint32_t node_id0;
        uint32_t node_id1;
        uint32_t node_id2;
        uint32_t node_id3;
        uint32_t num_leafs;
        uint32_t face_id;
        uint32_t face_num;
    } model_t;

    typedef struct {
        char name[16];
        uint32_t width;
        uint32_t height;
        uint32_t offset1;
        uint32_t offset2;
        uint32_t offset4;
        uint32_t offset8;
    } miptex_t;

    typedef struct {
        vec3_t vectorS;
        float distS;
        vec3_t vectorT;
        float distT;
        uint32_t texture_id;
        uint32_t animated;         
    } surface_t;

    typedef struct {
        uint32_t plane_id;
        uint16_t front;
        uint16_t back;
    } node_t;

    typedef struct { 
        uint16_t vertex0;
        uint16_t vertex1;
    } edge_t;   
]]

local function readInt32(file)
    local data = file:read(4)
    return ffi.cast('int32_t*', data)[0]
end

local function readHeader(file)
    local data = file:read(ffi.sizeof('header_t'))
    if not data then return nil end
    return ffi.cast("header_t*", data)[0]
end

local function readLump(file, lump, type)
    file:seek('set', lump.offset)
    local count = lump.length / ffi.sizeof(type)
    print(lump.offset, lump.length, count)

    -- Read entire lump at once
    local data = file:read(lump.length)
    if not data then return {} end

    -- Cast the entire buffer into an array of the structure type
    local array = ffi.cast(type .. "*", data)

    -- Convert to Lua table
    local result = {}
    for i = 1, count do
        result[i] = array[i - 1] -- Adjust 0-based index
    end
    return result
end

local function readPalette()
    local vfs_path = 'palette.lmp'
    local dir_path = lovr.filesystem.getRealDirectory(vfs_path)
    local path = dir_path .. '/' .. vfs_path
    local file = io.open(path, 'rb')

    local data = file:read("*all")  -- Read the entire file
    file:close()

    if #data ~= 768 then
        error("Invalid palette file size. Expected 768 bytes, got " .. #data)
    end

    local palette = ffi.new("uint8_t[256][3]")                     -- 256-color palette
    ffi.copy(palette, data, 768)

    return palette
end

local function readTextures(file, lump)
    local palette = readPalette()

    file:seek('set', lump.offset)
    local count = readInt32(file)

    local offsets = {}
    for i = 1, count do
        table.insert(offsets, readInt32(file))
    end

    local textures = {}
    for i, offset in ipairs(offsets) do
        local miptex_offset = lump.offset + offset
        file:seek('set', lump.offset + offset)

        local data = file:read(ffi.sizeof('miptex_t'))
        if not data then return nil end

        local tex_info = ffi.cast('miptex_t*', data)
        local tex_name = ffi.string(data)
        local tex_size = tex_info.width * tex_info.height
        local tex_offset = miptex_offset + tex_info.offset1

        file:seek('set', tex_offset)
        -- image data contains only indexed colors from a palette
        local img_data = file:read(tex_size)
        local img_buffer = ffi.cast('uint8_t*', img_data)
        -- output image will convert color index to rgba
        local out_size = tex_size * 4
        local out_buffer = ffi.new('uint8_t[?]', out_size)

        -- replace indexed colors with colors from palette
        for i = 0, tex_size - 1 do
            local color_idx = img_buffer[i]
            out_buffer[i * 4 + 0] = palette[color_idx][0]
            out_buffer[i * 4 + 1] = palette[color_idx][1]
            out_buffer[i * 4 + 2] = palette[color_idx][2]
            out_buffer[i * 4 + 3] = 255
        end

        -- now generate an image
        local blob = lovr.data.newBlob(ffi.string(out_buffer, tex_size * 4), tex_name)
        local image = lovr.data.newImage(tex_info.width, tex_info.height, 'rgba8', blob)
        table.insert(textures, image)

        channel:push({
            type = 'image',
            data = image,
            name = tex_name,
        })
    end

    return textures
end

local file = io.open(filename, 'rb')
if not file then
    print("Failed to open BSP file:", filename)
    return nil
end

local bsp = { 
    header      = {},
    -- lumps
    entities    = {},
    planes      = {}, 
    miptex      = {}, -- 3
    vertices    = {},
    visilist    = {},
    nodes       = {}, -- 6
    texinfo     = {},
    faces       = {},
    lightmaps   = {}, -- 9
    clipnodes   = {},
    leafs       = {}, 
    lface       = {}, -- 12
    edges       = {},
    ledges      = {},        
    models      = {}, -- 15
}

bsp.header = readHeader(file)
print("version: " .. bsp.header.version)

bsp.planes = readLump(file, bsp.header.planes, 'plane_t')
print('planes: ' .. #bsp.planes)
bsp.miptex = readTextures(file, bsp.header.miptex)
print('miptex: ' .. #bsp.miptex)
bsp.vertices = readLump(file, bsp.header.vertices, 'vertex_t')
print('vertices: ' .. #bsp.vertices)
bsp.texinfo = readLump(file, bsp.header.texinfo, 'surface_t')
print('texinfo: ' .. #bsp.texinfo)
bsp.faces = readLump(file, bsp.header.faces, 'face_t')
print('faces: ' .. #bsp.faces)
bsp.lface = readLump(file, bsp.header.lface, 'uint16_t')
print('lface: ' .. #bsp.lface)
bsp.edges = readLump(file, bsp.header.edges, 'edge_t')
print('edges: ' .. #bsp.edges)
-- bsp.models = readLump(file, bsp.header.models, 'model_t')
-- print('models: ' .. #bsp.models)

file:close()

