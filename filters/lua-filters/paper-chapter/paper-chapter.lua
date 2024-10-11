-- Create a chapter from a file with the metadata as read by the documentclass filters.
-- This works together with the includefile filter.

META = nil

local str = pandoc.utils.stringify

local function current_script()
	return debug.getinfo(2, "S").source:sub(2)
end

local function Header(...)
	local header = pandoc.Header(2, ...)
	header.classes = {
		"unlisted",
		"unnumbered",
	}
	return header
end

local function warn(...)
	io.stderr:write(table.concat(pandoc.List({ "WARNING", current_script(), ... }):map(str), " ") .. "\n")
end
local function warn_missing(...)
	warn("missing key in metadata:", ...)
end

local function is_valid_varname(varname)
	local valid = true
	if varname:sub(1, 1):match("%a") then
		for i = 2, #varname do
			if not varname:sub(i, i):match("%w") then
				valid = false
				break
			end
		end
	else
		valid = false
	end
	return valid
end

local function metapath(...)
	local a = ""
	for i, key in ipairs({ ... }) do
		if type(key) == "number" then
			a = a .. "[" .. key .. "]"
		elseif not is_valid_varname(str(key)) then
			a = a .. '["' .. key .. '"]'
		else
			if i > 1 then
				a = a .. "."
			end
			a = a .. key
		end
	end
	return a
end

local function metaget(...)
	local sel = META
	for _, key in ipairs({ ... }) do
		sel = sel[key]
	end
	assert(sel, "MISSING IN METADATA!\t" .. metapath(...))
	return sel
end

local function get_initials(name)
	local initials = ""
	for i = 1, #name do
		local char = name:sub(i, i)
		if char:match("%u") then
			initials = initials .. char
		end
	end
	return initials
end

local function blocks_institute_info()
	local marks = {}
	local blocks = pandoc.List()
	local list = pandoc.List()
	for i, row in ipairs(metaget("institute")) do
		assert(type(row) == "table", metapath("institute", i) .. " must be a table!")
		for key, institute in pairs(row) do
			assert(type(institute) == "table", metapath("institute", i, key) .. " must be a table!")
			marks[key] = pandoc.Superscript(pandoc.Str(i))
			-- local inlines = pandoc.Inlines{marks[key], pandoc.Space()}
			local inlines = pandoc.Inlines({})
			if institute.name then
				local address = pandoc.List()
				address:insert(institute.name)
				if institute.addressline then
					address:insert(institute.addressline)
				else
					warn_missing(metapath("institute", i, key, "addressline"))
				end
				if institute.city then
					if institute.postcode then
						address:insert(str(institute.postcode) .. " " .. str(institute.city))
					else
						warn_missing(metapath("institute", i, key, "postcode"))
						address:insert(institute.city)
					end
				else
					warn_missing(metapath("institute", i, key, "city"))
				end
				if institute.country then
					address:insert(institute.country)
				else
					warn_missing(metapath("institute", i, key, "country"))
				end
				for j, part in ipairs(address) do
					address[j] = pandoc.Str(str(part) .. (j < #address and ", " or ""))
				end
				inlines:extend(address)
			else
				warn_missing(metapath("institute", i, key, "name"))
			end
			list:insert(pandoc.Para(inlines))
		end
	end
	blocks:insert(pandoc.Para(pandoc.Strong("Institutions:")))
	blocks:insert(pandoc.OrderedList(list))

	local correspondence_counter = 0
	local new_authors = pandoc.List()
	for i, author in ipairs(metaget("authors")) do
		assert(type(author) == "table", metapath("author", i) .. " must be a table!")
		assert(
			type(author.institute) == "table" and #author.institute > 0,
			metapath("author", i, "institute") .. " must be a list!"
		)

		local annotations = pandoc.List()
		for _, key in ipairs(author.institute) do
			local mark = marks[str(key)]
			assert(mark, "Can not find an institute with key: " .. str(key))
			annotations:insert(mark)
		end

		if author.correspondence then
			correspondence_counter = correspondence_counter + 1
			local mark = pandoc.Superscript(string.rep("*", correspondence_counter))
			-- annotations:insert(mark)
			blocks:insert(pandoc.Para(pandoc.Inlines({
				-- mark, pandoc.Str(' Correspondence: '..str(metaget('author', i, author.name, 'email')))
				pandoc.Strong("Correspondence:"),
				pandoc.Space(),
				pandoc.Str(str(metaget("author", i, author.name, "email"))),
			})))
		end

		if author.equal then
			warn("Equal contributions are not implemented yet in this documentclass.")
		end

		if author.footnotes then
			warn("Author footnotes are not implemented yet in this documentclass.")
		end

		local inlines = pandoc.List()
		inlines:insert(pandoc.Str(str(author.name):gsub("{", ""):gsub("}", "")))
		for j, annotation in ipairs(annotations) do
			if j > 1 then
				inlines:insert(pandoc.Superscript(","))
			end
			inlines:insert(annotation)
		end
		new_authors:insert(inlines)
	end

	if #META.authors < 1 then
		error("No authors given!")
	end

	if correspondence_counter == 0 then
		warn_missing(metapath("author", 0, "???", "correspondence"), "(There is no corresponding author!)")
	end

	return { new_authors, pandoc.Blocks(blocks) }
end

local function blocks_author_contributions()
	local at_least_one = false
	local header = Header("Author contributions")

	local list = pandoc.List()
	for i, author in ipairs(META.authors) do
		if author.credit then
			at_least_one = true
			list:insert(pandoc.Strong(author.initials .. ": "))
			for j, contribution in ipairs(author.credit) do
				if j > 1 then
					list:insert(pandoc.Str(", "))
				end
				list:insert(pandoc.Str(str(contribution)))
			end
			list:insert(pandoc.Str(". "))
		else
			warn_missing(metapath("author", i, author.name, "credit"))
		end
	end

	if at_least_one then
		return pandoc.Blocks({ header, list })
	else
		return {}
	end
end

local function blocks_author()
	local list = pandoc.List()
	for i, author in ipairs(META.author) do
		local inlines = pandoc.List()
		inlines:extend(author)
		local orcid = str(META.authors[i].orcid)
		local link = pandoc.Link("ORCID: " .. orcid, "https://orcid.org/" .. orcid)
		if META.authors[i].orcid then
			inlines:extend({
				pandoc.RawInline("latex", "\\hfill{}"),
				pandoc.Str("("),
				link,
				pandoc.Str(")"),
			})
		end
		list:insert(pandoc.Para(inlines))
	end

	return pandoc.Blocks({
		pandoc.Para(pandoc.Strong("Authors:")),
		pandoc.BulletList(list),
	})
end

local function blocks_shorttitle()
	local shorttitle = metaget("shorttitle")
	if shorttitle then
		return pandoc.Blocks({ pandoc.RawBlock("latex", "\\chaptermark{" .. str(shorttitle) .. "}") })
	end
	return {}
end

local function blocks_keywords()
	if META.keywords then
		local header = Header("Keywords")
		return pandoc.Blocks({ header, pandoc.BulletList(META.keywords:map(str)) })
	else
		warn_missing(metapath("keywords"))
	end
	return {}
end

local function blocks_highlights()
	if META.highlights then
		local header = Header("Highlights")
		return pandoc.Blocks({ header, pandoc.BulletList(META.highlights:map(str)) })
	else
		warn_missing(metapath("highlights"))
	end
	return {}
end

local function blocks_text(heading, key)
	if not key then
		key = heading:lower():gsub(" ", "-")
	end
	if META[key] then
		local header = Header(heading)
		return pandoc.Blocks({ header, table.unpack(META[key]) })
	else
		warn_missing(metapath(key))
	end
	return {}
end

local function blocks_field(heading, key, content)
	if not key then
		key = heading:lower():gsub(" ", "-")
	end
	if not content then
		content = META[key]
		if content then
			content = str(content)
		end
	end
	if content then
		local label = pandoc.Strong(heading .. ":")
		return pandoc.Blocks({ pandoc.Para({ label, pandoc.Space(), content }) })
	else
		warn_missing(metapath(key))
	end
	return {}
end

local function blocks_doi()
	if META.doi then
		local doi = str(META.doi)
		return blocks_field("DOI", nil, pandoc.Link(doi, "https://doi.org/" .. doi))
	else
		warn_missing(metapath("doi"))
		return {}
	end
end

local function blocks_url()
	if META.url then
		local url = str(META.url)
		return blocks_field("URL", nil, pandoc.Link(url, url))
	else
		warn_missing(metapath("url"))
		return {}
	end
end

local function blocks_publication_info()
	local key = "publication-info"
	local info = META[key]
	if info then
		return info
	else
		warn_missing(metapath(key))
	end
	return {}
end

local function blocks_orcids()
	local at_least_one = false
	local header = Header("ORCIDs")

	local orcids = pandoc.List()
	for i, author in ipairs(META.authors) do
		if author.orcid then
			at_least_one = true
			local orcid = str(author.orcid)
			orcids:insert(pandoc.Para(pandoc.Inlines({
				pandoc.Link(orcid, "https://orcid.org/" .. orcid),
				pandoc.Str(":"),
				pandoc.Space(),
				pandoc.Str(str(author.initials)),
			})))
		else
			warn_missing(metapath("author", i, author.name, "orcid"))
		end
	end

	if at_least_one then
		return pandoc.Blocks({ header, pandoc.BulletList(orcids) })
	else
		return {}
	end
end

local function format_paper_chapter(cb, filename)
	local blocks = pandoc.List()

	local instinfo = blocks_institute_info()
	META.author = instinfo[1]

	blocks:extend(pandoc.Blocks({ pandoc.Header(1, pandoc.utils.blocks_to_inlines(metaget("title"))) }))

	-- for i, author in ipairs(META.authors) do
	--     for key, value in pairs(author) do
	--         print(key, value)
	--     end
	-- end

	blocks:extend(blocks_publication_info())
	blocks:extend(blocks_author())
	blocks:extend(instinfo[2])
	blocks:extend(blocks_shorttitle())
	blocks:extend(blocks_field("Date"))
	blocks:extend(blocks_doi())
	blocks:extend(blocks_url())
	blocks:extend(blocks_field("Editor"))
	-- blocks:extend({pandoc.RawBlock('latex', '\\newpage')})

	blocks:extend(blocks_keywords())
	blocks:extend(blocks_highlights())
	blocks:extend(blocks_text("Abstract"))
	blocks:extend(blocks_text("Popular summary", "simple-abstract"))

	local c = pandoc.CodeBlock(filename)
	c.attr = cb.attr:clone()
	local _, idx = c.classes:find("paperchapter")
	c.classes:remove(idx)
	c.classes:insert("include")
	blocks:extend({ c })

	blocks:extend(blocks_text("Acknowledgments"))
	blocks:extend(blocks_text("Funding"))
	blocks:extend(blocks_text("Competing interests", "conflicts"))
	blocks:extend(blocks_text("Copyright"))
	blocks:extend(blocks_text("Peer review history"))
	blocks:extend(blocks_author_contributions())
	-- blocks:extend(blocks_orcids())

	return blocks
end

local function store_metadata(meta)
	META = meta

	for _, key in ipairs({ "abstract", "title", "date", "author" }) do
		if not META[key] then
			warn_missing(metapath(key))
		end
	end

	local blocks = pandoc.List()
	blocks:insert(pandoc.RawBlock(
		"latex",
		[[
        \usepackage{balance}
        \usepackage[labelfont={bf,small},textfont={small}]{caption}
    ]]
	))

	if not META["header-includes"] then
		META["header-includes"] = {}
	end
	for _, block in ipairs(blocks) do
		table.insert(META["header-includes"], block)
	end

	local authors = pandoc.List()
	assert(#metaget("author") > 0, metapath("author") .. " must be a list!")
	for i, author in ipairs(META.author) do
		assert(type(author) == "table" and #author == 0, metapath("author", i) .. " must be a dictionary!")
		for name, a_ in pairs(author) do
			local a = {}
			assert(type(a_) == "table" and #a_ == 0, metapath("author", i, name) .. " must be a dictionary!")
			for k, v in pairs(a_) do
				a[k] = v
			end
			if not a.initials then
				a.initials = get_initials(name)
			end
			a.initials = pandoc.utils.stringify(a.initials)
			a.name = name
			authors:insert(a)
		end
	end
	META.authors = authors

	if not META.geometry then
		META.geometry = { "a4paper", "margin=30mm" }
	else
		warn("using geometry in YAML header")
	end

	return META
end

local function replace_code_block(cb)
	-- ignore code blocks which are not of class "paperchapter".
	if not cb.classes:includes("paperchapter") then
		return
	end

	-- Markdown is used if this is nil.
	local format = cb.attributes["format"]

	local blocks = pandoc.List()
	for line in cb.text:gmatch("[^\n]+") do
		if line:sub(1, 2) ~= "//" then
			local fh = io.open(line)
			if not fh then
				io.stderr:write("Cannot open file " .. line .. " | Skipping includes\n")
			else
				-- read file as the given format with global reader options
				local META = pandoc.read(fh:read("*a"), format, PANDOC_READER_OPTIONS).meta
				fh:close()
				if META then
					store_metadata(META)
					blocks:extend(format_paper_chapter(cb, line))
				end
			end
		end
	end

	return blocks
end

return {
	{ CodeBlock = replace_code_block },
}
