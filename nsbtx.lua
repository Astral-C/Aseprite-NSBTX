local function color5To8(value)
    return (value << 3) | (value >> 2)
end

local function readDict(file, readFunc, args)
    file:seek("cur", 1)
    local size = string.unpack("<b", file:read(1))

    local values = {}
    local items = {}

    file:seek("cur", 2 + 8 + (4 * size) + 4) -- skip things we don't need

    for i = 1, size, 1 do
        values[i] = readFunc(file, args)
    end

    for i = 1, size, 1 do
        local name = string.unpack("<c16", file:read(16)):gsub("%z+$", ""):gsub("%z+", "")
        items[i] = { name, values[i] }
    end

    return items
end

local function readPalette(file, args)
    local palette = Palette()

    local paletteOffset = (string.unpack("<H", file:read(2)) << 3) + args[1]
    local listPos = file:seek("cur")

    local colorCount = args[2] / 2

    file:seek("set", paletteOffset)
    palette:resize(colorCount)
    for i = 0, colorCount - 1, 1 do
        local entry = string.unpack("<H", file:read(2))
        palette:setColor(i,
            Color { r = color5To8(entry & 0x1F), g = color5To8((entry >> 5) & 0x1F), b = color5To8((entry >> 10) & 0x1F) })
    end

    file:seek("set", listPos)

    return palette
end

local function readTexture(file, args)
    local texture = {}

    local params = string.unpack("<I4", file:read(4))
    texture["format"] = (params >> 26) & 0x07
    texture["width"] = 8 << ((params >> 20) & 0x07)
    texture["height"] = 8 << ((params >> 23) & 0x07)
    texture["color0"] = (params >> 29) & 0x01

    local dataOffset = (params & 0xFFFF) << 3
    local readPos = file:seek("cur")

    file:seek("set", args[1] + dataOffset)
    texture["data"] = Image(texture["width"], texture["height"], ColorMode.INDEXED)

    if texture["format"] == 0x02 then
        for y = 1, texture["height"], 1 do
            for x = 1, texture["width"], 8 do
                local block = string.unpack("<H", file:read(2))
                for bx = 1, 4, 1 do
                    local paletteIdx = block & 0x03
                    texture["data"]:putPixel(x + bx, y, paletteIdx)
                    block = block >> 2
                end
            end
        end
    elseif texture["format"] == 0x03 then
        for y = 1, texture["height"], 1 do
            for x = 1, texture["width"], 4 do
                local block = string.unpack("<H", file:read(2))
                for bx = 1, 4, 1 do
                    local paletteIdx = block & 0x0F
                    texture["data"]:putPixel(x + bx, y, paletteIdx)
                    block = block >> 4
                end
            end
        end
    elseif texture["format"] == 0x04 then
        for y = 1, texture["height"], 1 do
            for x = 1, texture["width"], 1 do
                texture["data"]:putPixel(x, y, string.unpack("<b", file:read(1)))
            end
        end
    end
    file:seek("set", readPos)
    file:seek("cur", 4)
    return texture
end

local function import(plugin)
    local dlg = Dialog("Import NSBTX")

    dlg:file {
        id = "source",
        label = "Source:",
        filetypes = { "nsbtx" },
        load = true,
        focus = true,
    }

    dlg:check {
        id = "textureascel",
        label = "Texture as Cel"
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
            if "BTX0" ~= magic then
                return
            end

            file:seek("set", 14)

            local sectionCount = string.unpack("<H", file:read(2))

            for i = 1, sectionCount, 1 do
                local sectionOffset = string.unpack("<I4", file:read(4))
                local returnOffset = file:seek("cur")

                local stamp = string.unpack("<c4", file:read(4))
                if stamp == "TEX0" then
                    file:seek("cur", 8) -- skip size and unknown
                    local textureDataSize, textureListOff, _, textureDataOff, _ = string.unpack("<HHI4I4I4",
                        file:read(16))
                    local cmpTexDataSize, cmpTexInfoOffset, _ = string.unpack("<HHI4", file:read(8))
                    local cmpTexDataOffset, cmpTexInfoDataOffset, _ = string.unpack("<I4I4I4", file:read(12))
                    local paletteDataSize, paletteDictOffset, _, paletteDataOffset = string.unpack("<I4HHI4",
                        file:read(12))

                    cmpTexDataSize = cmpTexDataSize << 3
                    paletteDataSize = paletteDataSize << 3


                    file:seek("set", sectionOffset + paletteDictOffset)
                    local palettes = readDict(file, readPalette, { sectionOffset + paletteDataOffset, paletteDataSize })

                    file:seek("set", sectionOffset + textureListOff)
                    local nxbtx_images = readDict(file, readTexture, { sectionOffset + textureDataOff, textureDataSize })

                    local sprite = Sprite(nxbtx_images[1][2]["width"], nxbtx_images[1][2]["height"], ColorMode.INDEXED)

                    if not dlg.data.textureascel then
                        sprite:deleteLayer(sprite.layers[1])
                    end

                    local frame = 1
                    for name, value in ipairs(nxbtx_images) do
                        if dlg.data.textureascel then
                            if #sprite.frames - 1 <= frame then
                                sprite:newEmptyFrame()
                            end
                            sprite:newCel(sprite.layers[1], frame, value[2]["data"])
                            frame = frame + 1
                        else
                            local layer = sprite:newLayer()
                            layer.name = value[1]
                            sprite:newCel(layer, 1, value[2]["data"])
                        end
                    end

                    for name, value in ipairs(palettes) do
                        sprite:setPalette(value[2])
                    end
                end

                file:seek("set", returnOffset)
            end

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
