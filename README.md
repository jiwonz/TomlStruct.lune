# TomlStruct.lune
Structurable `toml` parser for `lune`

## Note
kinda messy and can be buggy (but tested)

## Features
- Runtime typechecking
- Setting item orders
- Adding blank lines
- Inline tables
- Decode by `@lune/serde` and typecheck

## Example
```lua
local toml = TomlStruct(
	{ "sans", "table" }, -- { keyName, valueType }
	{ "hello", "string" },
	{ }, -- skip this line!
	{ "goodboy", -- table
		{ "key", "string" },
		{ "deep",
			{ "omg", "number?" }, -- optional value
			{ "test", "table" } -- inline table or array or array table
		}
	}
)

local tbl = {
	hello = "hi",
	sans = { "ez", "yes" },
	goodboy = {
		key = ":)",
		deep = {
			omg = 5,
			test = { 1, 2, 3 }
		}
	}
}

local encoded = toml:encode(tbl)
print("encoded:\n", encoded)

local decoded = toml:decode(encoded)
print("decoded:\n", decoded)
```

## Credit
[toml.lua](https://github.com/jonstoler/lua-toml)
