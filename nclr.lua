local function color5To8(value)
    return (value << 3) | (value >> 2)
end

local function import(plugin)
    local dlg = Dialog("Import NCLR")

    dlg:file {
        id = "source",
        label = "Source:",
        filetypes = { "nclr", "rlcn" },
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
            if "RLCN" ~= magic then
                return
            end

            file:seek("set", 16)

            local sprite = app.sprite

            file:seek("cur", 8) -- skip pltt magic & section size
            local bitDepth = string.unpack("<I4", file:read(4))
            file:seek("cur", 4) -- skip 0
            local paletteDataSize = string.unpack("<I4", file:read(4))

            if 0x200 - paletteDataSize > 0 then
                paletteDataSize = 0x200 - paletteDataSize
            end

            if bitDepth == 4 then
                paletteDataSize = 0x200
            end

            local colorCount = string.unpack("<I4", file:read(4))
            local palette = Palette()
            palette:resize(colorCount)

            for i = 1, colorCount - 1, 1 do
                local c = string.unpack("<H", file:read(2))
                palette:setColor(i - 1, Color {
                    r = color5To8(c & 0x1F), g = color5To8((c >> 5) & 0x1F), b = color5To8((c >> 10) & 0x1F)
                })
            end

            sprite:setPalette(palette)
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
