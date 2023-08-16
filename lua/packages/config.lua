-- Libraries
local timer = timer
local table = table
local file = file
local util = util

-- Variables
local setmetatable = setmetatable
local gPackage = gpm.Package
local ArgAssert = ArgAssert
local logger = gpm.Logger
local pairs = pairs
local type = type

module( "config" )

local meta = {}
meta.__index = meta

-- Config name
function meta:GetName()
    return self.Name
end

-- tostring method
function meta:__tostring()
    return "Config File [" .. self:GetName() .. "]"
end

-- Getting path to config file in 'garrysmod/atmosphere/'
function meta:GetFilePath()
    return "config/" .. self:GetName() .. ".json"
end

-- Config file exists check
function meta:IsFileExists()
    return file.Exists( self:GetFilePath(), "DATA" )
end

-- Defaults
function meta:GetDefaults()
    return self.Defaults
end

function meta:SetDefaults( tbl )
    self.Defaults = tbl
end

-- Data reset
function meta:Reset()
    local tbl = self.Table
    table.Empty( tbl )

    local defaults = self:GetDefaults()
    if not defaults then return end

    for key, value in pairs( defaults ) do
        tbl[ key ] = value
    end
end

-- Getting all data table
function meta:GetTable()
    return self.Table
end

-- Getting a value from a key
function meta:Get( key, default )
    local value = self.Table[ key ]
    if value ~= nil then return value end
    return default
end

-- Setting a value using a key
function meta:Set( key, value )
    self.Table[ key ] = value

    timer.Create( gPackage:GetIdentifier( self:GetName() ), 0.25, 1, function()
        self:Save()
    end )
end

-- Data saving
function meta:Save()
    file.Write( self:GetFilePath(), util.TableToJSON( self.Table, true ) )
    logger:Debug( "Config \'%s\' was saved.", self.Name )
end

-- Data loading
function meta:Load()
    if not self:IsFileExists() then
        return logger:Error( "Config file \'%s\' does not exist.", self:GetFilePath() )
    end

    local tbl = util.JSONToTable( file.Read( self:GetFilePath(), "DATA" ) )
    if not tbl then
        return logger:Error( "JSON file structure is damaged, file: %s", self:GetFilePath() )
    end

    table.Empty( self.Table )

    for key, value in pairs( tbl ) do
        self.Table[ key ] = value
    end

    logger:Debug( "Config \'%s\' was loaded.", self.Name )
end

-- Creating a new config file
function Create( name, defaults )
    ArgAssert( name, 1, "string" )

    local config = {
        ["Name"] = name,
        ["Table"] = {}
    }

    if type( defaults ) == "table" then
        config.Defaults = defaults
    end

    setmetatable( config, meta )
    logger:Debug( "Config \'%s\' was created.", name )

    if config:IsFileExists() then
        config:Load()
        return config
    end

    config:Reset()
    config:Save()
    return config
end

-- Removing exists config file
function Remove( name )
    ArgAssert( name, 1, "string" )
    file.Delete( "config/" .. name .. ".json" )
end
