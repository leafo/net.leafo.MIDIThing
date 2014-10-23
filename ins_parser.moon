
class InsParser
  bank_section: "Instrument Definitions"
  bank_instrument_section: "Patch Names"

  parse: (fname) =>
    sections = {}

    local current_section
    local current_group

    line_no = 0
    file = assert io.open fname
    for line in file\lines!
      line_no += 1
      continue if @parse_comment line

      if section = @parse_section_header line
        current_section = {}
        sections[section] = current_section
        continue

      if group = @parse_group_header line
        assert current_section, "got group without section (#{line_no})"
        -- assert not current_section[group], "section already contains groups `#{group}` (#{line_no})"

        current_group = {}
        current_section[group] = current_group
        continue

      key, value = @parse_tuple line
      if key
        assert current_group, "got tuple without group (#{line_no})"
        key = tonumber(key) or key
        -- assert not current_group[key], "group already contains key `#{key}` (#{line_no})"
        current_group[key] = value

    @transform_sections sections

  transform_sections: (parsed) =>
    -- extract all the banks and associate with program numbers
    bank_instruments = parsed[@bank_instrument_section], "missing patch definition section `#{@bank_instrument_section}`"

    modules = assert parsed[@bank_section], "missing bank definition section `#{@bank_section}`"

    modules_banks = {}
    for name, bank_defs in pairs modules
      banks = for k,v in pairs bank_defs
        bank = k\match "Patch%[(%d+)%]"
        continue unless bank
        bank = tonumber bank
        continue unless bank

        instruments = bank_instruments[v]
        continue unless instruments
        continue unless next instruments
        instruments = {k,v for k,v in pairs instruments when type(k) == "number"}

        {
          :bank
          name: v
          :instruments
        }

      table.sort banks, (a,b) ->
        a.bank < b.bank

      modules_banks[name] = banks

    modules_banks

  parse_comment: (line) =>
    line\match "^%s*%;"

  parse_section_header: (line) =>
    line\match "^%s*%.(.-)%s*$"

  parse_group_header: (line) =>
    line\match "^%[(.-)%]%s*$"

  parse_tuple: (line) =>
    line\match "^%s*(.-)=(.-)%s*$"

  compile_to_lua: (parsed) =>
    encode_value = (val) ->
      switch type(val)
        when "string"
          delim = if not val\match "'"
            "'"
          elseif not val\match '"'
            '"'
          else
            "[==["

          {"string", delim, val}
        when "number"
          {"number", val}
        when "table"
          {
            "table"
            for k,v in pairs val
              {
                if type(k) == "string" and k\match "^[_%a][%w_]*$"
                  {"key_literal", k}
                else
                  encode_value k

                encode_value v
              }
          }

    compile = require("moonscript.compile")
    compile.tree {
      encode_value parsed
    }

parser = InsParser!
raw = parser\parse assert ..., "missing fname"
print assert (parser\compile_to_lua raw), "failed to compile"
