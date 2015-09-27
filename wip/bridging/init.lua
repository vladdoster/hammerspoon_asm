--- === hs._asm.bridging ===
---
--- Playing with a simplistic lua-objc bridge.
---
--- Very experimental.  Don't use or trust.  Probably forget you ever saw this.
---
--- In fact, burn any computer it has come in contact with.  When (not if) you crash Hammerspoon, it's on your own head.

local defaultPaths = "/System/Library/Frameworks;/Library/Frameworks"

local module  = require("hs._asm.bridging.internal")
local xml     = require("hs._asm.xml")
local fnutils = require("hs.fnutils")
local fs      = require("hs.fs")

-- private variables and methods -----------------------------------------

local _kMetaTable = {}
_kMetaTable._k = {}
_kMetaTable.__index = function(obj, key)
        if _kMetaTable._k[obj] then
            if _kMetaTable._k[obj][key] then
                return _kMetaTable._k[obj][key]
            else
                for k,v in pairs(_kMetaTable._k[obj]) do
                    if v == key then return k end
                end
            end
        end
        return nil
    end
_kMetaTable.__newindex = function(obj, key, value)
        error("attempt to modify a table of constants",2)
        return nil
    end
_kMetaTable.__pairs = function(obj) return pairs(_kMetaTable._k[obj]) end
_kMetaTable.__tostring = function(obj)
        local result = ""
        if _kMetaTable._k[obj] then
            local width = 0
            for k,v in pairs(_kMetaTable._k[obj]) do width = width < #k and #k or width end
            for k,v in require("hs.fnutils").sortByKeys(_kMetaTable._k[obj]) do
                result = result..string.format("%-"..tostring(width).."s %s\n", k, tostring(v))
            end
        else
            result = "constants table missing"
        end
        return result
    end
_kMetaTable.__metatable = _kMetaTable -- go ahead and look, but don't unset this

local _makeConstantsTable = function(theTable)
    local results = setmetatable({}, _kMetaTable)
    _kMetaTable._k[results] = theTable
    return results
end

-- Public interface ------------------------------------------------------
local frameworkCache = {}
module.frameworkCache = frameworkCache

module.importFramework = function(name, paths)
    if frameworkCache[name] then return frameworkCache[name] end

    paths = paths and paths..";" or ""
    paths = paths..defaultPaths

    for i,v in ipairs(fnutils.split(paths,";")) do
        local testPath = v.."/"..name..".framework/Resources/BridgeSupport/"
--         print(testPath)
        if fs.attributes(testPath..name..".bridgesupport") then
            frameworkCache[name] = {
                bridge = testPath..name..".bridgesupport",
                xml    = xml.open(testPath..name..".bridgesupport"),
                dylib  = package.loadlib(testPath..name..".dylib","*")
            }
            break
        end
    end

    if frameworkCache[name] then
        return frameworkCache[name]
    else
        return error(name.." framework not found", 2)
    end
end

-- Return Module Object --------------------------------------------------

return module
