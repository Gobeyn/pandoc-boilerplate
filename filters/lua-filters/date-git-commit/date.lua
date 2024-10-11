--[[
    Set the date in the metadata to the date and time of the last git commit.
--]]

local function cmd(c)
	local handle = io.popen(c)
	assert(handle)
	local s = handle:read("*a")
	handle:close()
	return s
end

local function lang_to_locale(lang)
	if not lang then
		return "en-GB"
	elseif #lang == 2 then
		return lang:lower() .. "-" .. lang:upper()
	end
	return lang:gsub("_", "-")
end

local function default_format(locale)
	if locale == "de-DE" then
		return "+%e. %B %Y"
	elseif locale == "en-US" or locale == "en-GB" then
		return "+%e %B %Y"
	else
		return "+%F"
	end
end

function Meta(m)
	local locale = lang_to_locale(pandoc.utils.stringify(m.lang or "en-GB"))
	local format = pandoc.utils.stringify(m.date or default_format(locale))
	if format:sub(1, 1) ~= "+" then
		return
	end
	m.date = cmd("git diff --exit-code 2>&1 >/dev/null && git log -1 --format='%at' || date '+%s'")
	m.date = cmd("LC_ALL=" .. locale .. ".UTF8 date -d '@" .. m.date:gsub("\n", "") .. "' '" .. format .. "'")
	print("setting date to: " .. m.date)
	return m
end
