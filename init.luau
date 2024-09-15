--!strict

local serde = require("@lune/serde")
local stdio = require("@lune/stdio")

export type KVItem = { "string" | "number" | "boolean" | "table" | "any" | string | KVItem }

export type TomlStruct<T> = {
	encode: (self: TomlStruct<T>, tbl: T, pretty: boolean) -> string,
	decode: (self: TomlStruct<T>, toml: string) -> T,
}

local TomlStruct = {} :: TomlStruct<any>;
(TomlStruct :: any).__index = TomlStruct

local function toKeyValues(tbl: { [any]: any }): { KVItem }
	local keyValues = {}
	for k, v in tbl do
		table.insert(keyValues, { k, typeof(v) })
	end
	return keyValues
end

local function toString(str: any)
	if type(str) == "string" then
		return '"' .. str .. '"'
	end
	return tostring(str)
end

function TomlStruct.encode(self, tbl: any, pretty: boolean)
	if type(tbl :: any) ~= "table" then
		error("Only table can be encoded into toml!")
	end

	local toml = ""

	local cache = {}
	local wasBlank = false

	local function parse(t, struct: any)
		for _, keyValue in struct :: any do
			local key = keyValue[1]
			local valueType = keyValue[2]
			if key == nil then
				if not wasBlank then
					toml ..= "\n"
				end
				wasBlank = true
				continue
			end
			wasBlank = false
			local optional
			if type(valueType) == "string" then
				optional = valueType:sub(-1) == "?"
				if optional then
					valueType = valueType:sub(1, -2)
				end
			end
			local value = t[key]
			if (value == nil and optional) or (valueType == nil and value == nil) then
				continue
			end
			local isAny = false
			if valueType == "any" then
				valueType = typeof(value)
				isAny = true
			end
			if not isAny and typeof(value) ~= valueType and type(valueType) == "string" then
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
				--value = value:gsub("/", "\\/") wtf?
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
						for _, vv in pairs(value) do
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
						for _, vv in first do
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
			elseif type(valueType) == "table" or valueType == nil then
				if value then
					-- just a key/value table, folks
					table.insert(cache, key)
					toml = toml .. "[" .. table.concat(cache, ".") .. "]\n"
					--table.remove(cache)
				end
				local st = {}
				optional = false
				if valueType == nil then
					for k, v in value do
						table.insert(st, { k, typeof(v) })
					end
					table.remove(cache)
				else
					for i = 2, #keyValue do
						local item = keyValue[i]
						if type(item) == "table" then
							table.insert(st, keyValue[i])
						elseif item == "?" then
							optional = true
						end
					end
				end
				if value == nil then
					if optional then
						continue
					else
						error(`pack of KVItem is required for key '{key}'`)
					end
				end
				parse(value, st)
			end
			local conditionalCallback = keyValue[3]
			if conditionalCallback then
				local valid, msg = conditionalCallback(value)
				if not valid then
					error(`Conditional callback assertion failed{ if msg ~= nil then`: {msg} ` else "" }(got {stdio.format(value)})`)
				end
			end
		end
	end
	parse(tbl, self)

	local result = toml:sub(1, -2)

	if pretty then
		result = result:gsub("^%s*(.-)%s*$", "%1")
		if result:sub(-1) ~= "\n" then
			result ..= "\n"
		end
	end

	return result
end

function TomlStruct.decode(self, toml)
	local t = serde.decode("toml", toml)
	for _, keyValue in self :: any do
		local key = keyValue[1]
		local valueType = keyValue[2]
		if key == nil then
			continue
		end
		local value = t[key]
		local optional
		if type(valueType) == "string" then
			optional = valueType:sub(-1) == "?"
			if optional then
				valueType = valueType:sub(1, -2)
			end
		end
		if (value == nil and optional) or (valueType == nil and value == nil) then
			continue
		end
		if valueType ~= "any" and typeof(value) ~= valueType and type(valueType) == "string" then
			error("Invalid value type '" .. typeof(value) .. "' expected '" .. valueType .. "'")
		end
	end
	return t
end

return function(...: KVItem): TomlStruct<any>
	return setmetatable({ ... }, TomlStruct) :: any
end
