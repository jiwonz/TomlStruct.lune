# TomlStruct.lune
Flexible and structurable `toml` parser for `lune`

## Note
kinda messy and can be buggy (but tested)

## Features
- Runtime typechecking
- Setting item orders
- Adding blank lines
- Inline tables
- Decode with `@lune/serde` and typecheck

## Example
```lua
local toml = TomlStruct(
	{ "sans", "table" }, -- { keyName, valueType }
	{ "hello", "any" }, -- any type
	{ }, -- skip this line!
	{ "goodboy", -- table
		{ "key", "string" },
		{ "deep",
			{ "omg", "number?" }, -- optional value
			{ "test", "table" } -- inline table or array or array table
		},
		{ "objects" } -- blank table (any items can be written into it!)
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
		},
		objects = {
			anything = "xd"
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
