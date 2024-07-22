--!strict

local serde
if _VERSION:find("Lune") then
	serde = require("@lune/serde")
end

export type KVItem = { "string" | "number" | "table" | string | KVItem }

export type TomlStruct<T> = typeof(setmetatable(
	{} :: {},
	{} :: TomlStructImpl
))

type TomlStructImpl = {
	__index: TomlStructImpl,
	encode: <T>(self: TomlStruct<T>, tbl: T) -> (string),
	decode: <T>(self: TomlStruct<T>, toml: string) -> (T),
}

local TomlStruct = {} :: TomlStructImpl
TomlStruct.__index = TomlStruct

local function toKeyValues(tbl: { [any]: any }): { KVItem }
	local keyValues = {}
	for k, v in tbl do
		table.insert(keyValues, { k, typeof(v) })
	end
	return keyValues
end

local function toString(str: any)
	if type(str) == "string" then
		return "\"" .. str .. "\""
	end
	return tostring(str)
end

function TomlStruct.encode(self, tbl: any)
	if type(tbl :: any) ~= "table" then
		error("Only table can be encoded into toml!")
	end

	local toml = ""

	local cache = {}

	local function parse(t, struct: any)
		for _, keyValue in struct :: any do
			local key = keyValue[1]
			local valueType = keyValue[2]
			if key == nil or valueType == nil then
				toml ..= "\n"
				continue
			end
			local value = t[key]
			if typeof(value) ~= valueType and type(valueType) == "string" then
				print(keyValue)
				error("Invalid value type '" .. typeof(value) .. "' expected '" .. valueType .. "'")
			end
			if valueType == "boolean" or valueType == "number" then
				toml = toml .. key .. " = " .. toString(value) .. "\n"
			elseif valueType == "string" then
				local quote = '"'
				value = value:gsub("\\", "\\\\")

				-- if the string has any line breaks, make it multiline
				if value:match("^\n(.*)$") then
					quote = quote:rep(3)
					value = "\\n" .. value
				elseif value:match("\n") then
					quote = quote:rep(3)
				end

				value = value:gsub("\b", "\\b")
				value = value:gsub("\t", "\\t")
				value = value:gsub("\f", "\\f")
				value = value:gsub("\r", "\\r")
				value = value:gsub('"', '\\"')
				value = value:gsub("/", "\\/")
				toml = toml .. key .. " = " .. quote .. value .. quote .. "\n"
			elseif valueType == "table" then -- including: array, table array, inline table
				local array, arrayTable = true, true
				local first = {} -- 값이 테이블이 아닌것들 (먼저 파싱해야하는거)
				for kk, vv in pairs(value) do
					if type(kk) ~= "number" then
						array = false
					end
					if type(vv) ~= "table" then -- 테이블이 아닌것들은 먼저 해야함
						value[kk] = nil
						first[kk] = vv
						arrayTable = false
					end
				end

				if array then
					if arrayTable then
						-- double bracket syntax go!
						--[[
						{
							{
								key = value
							},
							{
								key = value
							},
						}
						]]
						table.insert(cache, key)
						for kk, vv in pairs(value) do
							toml = toml .. "[[" .. table.concat(cache, ".") .. "]]\n"
							for k3, v3 in vv do
								if type(v3) ~= "table" then
									vv[k3] = nil
									first[k3] = v3
								end
							end
							parse(first, toKeyValues(first))
							parse(vv, toKeyValues(vv))
							-- parse(first)
							-- parse(vv)
						end
						table.remove(cache)
					else
						-- plain ol boring array
						toml ..= key .. " = [ "
						for kk, vv in first do
							toml ..= toString(vv) .. ", "
						end
						toml = toml:sub(1, -3)
						toml ..= " ]\n"
					end
				else
					-- inline table
					toml ..= key .. " = { "
					for kk, vv in first do
						toml ..= tostring(kk) .. " = " .. toString(vv) .. ", "
					end
					toml = toml:sub(1, -3)
					toml ..= " }\n"
				end
			elseif type(valueType) == "table" then
				-- just a key/value table, folks
				table.insert(cache, key)
				toml = toml .. "[" .. table.concat(cache, ".") .. "]\n"
				--table.remove(cache)

				local st = {}
				for i = 2, #keyValue do
					table.insert(st , keyValue[i])
				end
				--print(st)
				parse(value, st)
			end
		end
	end
	parse(tbl, self)

	return toml:sub(1, -2)
end

function TomlStruct.decode(self, toml)
	local t = serde.decode("toml", toml)
	for _, keyValue in self :: any do
		local key = keyValue[1]
		local valueType = keyValue[2]
		if key == nil or valueType == nil then
			continue
		end
		local value = t[key]
		if typeof(value) ~= valueType and type(valueType) == "string" then
			print(keyValue)
			error("Invalid value type '" .. typeof(value) .. "' expected '" .. valueType .. "'")
		end
	end
	return t
end

return function(...: KVItem): TomlStruct<any>
	return setmetatable({ ... }, TomlStruct) :: any
end
