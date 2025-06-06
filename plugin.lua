function init(plugin)
    plugin:newCommand {
        id = "nsbtx_import",
        title = "Import NSBTX",
        group = "file_import_1",
        onclick = function()
            dofile(app.fs.joinPath(plugin.path, "nsbtx.lua")).import(plugin)
        end,
    }

    plugin:newCommand {
        id = "ncgr_import",
        title = "Import NCGR",
        group = "file_import_1",
        onclick = function()
            dofile(app.fs.joinPath(plugin.path, "ncgr.lua")).import(plugin)
        end,
    }

    plugin:newCommand {
        id = "nclr_import",
        title = "Import NCLR",
        group = "palette_files",
        onclick = function()
            dofile(app.fs.joinPath(plugin.path, "nclr.lua")).import(plugin)
        end,
    }

    plugin:newCommand {
        id = "nsbtx_export",
        title = "Export NSBTX",
        group = "file_export_1",
        onclick = function()
            dofile(app.fs.joinPath(plugin.path, "nsbtx.lua")).export(plugin)
        end,
        onenabled = function()
            return app.sprite ~= nil
        end,
    }
end
