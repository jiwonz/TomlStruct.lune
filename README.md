# TomlStruct.lune
Structurable `toml` parser for `lune`

## Note
kinda messy and can be buggy

## Example
```lua
local toml = TomlStruct(
	{ "sans", "table" },
	{ "hello", "string" },
	{ },
	{ "goodboy",
		{ "key", "string" },
		{ "deep",
			{ "omg", "number" },
			{ "test", "table" }
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
