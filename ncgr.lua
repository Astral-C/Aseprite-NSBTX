local function color5To8(value)
    return (value << 3) | (value >> 2)
end

local function import(plugin)
    local dlg = Dialog("Import NCGR")

    dlg:file {
        id = "source",
        label = "Source:",
        filetypes = { "ncgr", "rgcn" },
        load = true,
        focus = true,
    }

    dlg:button {
        text = "Import",
        onclick = function()
            local source = dlg.data.source
            if not source then
                return
            end

            local file <close> = io.open(source, "rb")
            if not file then
                return
            end

            local magic = string.unpack("<c4", file:read(4))
            if "RGCN" ~= magic then
                return
            end

            local log = io.open("log.txt", "w")
            file:seek("set", 16)

            file:seek("cur", 8) -- skip pltt magic & section size
            file:seek("cur", 4) -- skip tile width and tile height
            local bitDepth = string.unpack("<I4", file:read(4))

            file:seek("cur", 8)
            local tileDataSize, tileDataOffset = string.unpack("<I4I4", file:read(8))

            log:write("Bit depth is ", bitDepth, "\n")

            local tileCount = 0
            if bitDepth == 3 then
                tileCount = tileDataSize / 32
            else
                tileCount = tileDataSize / 64
            end

            local tiles = {}

            file:seek("set", tileDataOffset + 24)
            log:write("Reading #", tileCount, " at ", file:seek("cur"), "\n")

            for i = 1, tileCount, 1 do
                tiles[i] = {}
                if bitDepth == 3 then
                    for j = 0, 31, 1 do
                        local byte = string.unpack("<b", file:read(1))
                        tiles[i][(j * 2) + 1] = byte & 0xF
                        tiles[i][(j * 2 + 1) + 1] = byte >> 4
                    end
                else
                    for j = 1, 64, 1 do
                        tiles[i][j] = string.unpack("<b", file:read(1))
                    end
                end
            end

            local sprite = app.sprite

            local image = Image(sprite.width, sprite.height, ColorMode.INDEXED)
            local tileIDX = 1

            for ty = 0, sprite.height - 8, 8 do
                for tx = 0, sprite.width - 8, 8 do
                    if tileIDX > #tiles then
                        break
                    end
                    log:write("Writing tile #", tileIDX, " at ", tx, "x", ty, "\n")
                    for y = 0, 7, 1 do
                        for x = 0, 7, 1 do
                            log:write("Writing Pixel at ", tx + x, "x", ty + y, "\n")
                            local idx = tiles[tileIDX][((y * 8) + x) + 1]
                            image:putPixel(x + tx, y + ty, idx)
                        end
                    end
                    tileIDX = tileIDX + 1
                end
            end

            sprite:newCel(sprite.layers[1], 1, image)

            app.frame = 1

            dlg:close()
        end
    }

    dlg:label {
        label = "Version:",
        text = "0.1-dev"
    }

    dlg:show()
end

local function export(plugin)

end

return {
    import = import,
    export = export
}
