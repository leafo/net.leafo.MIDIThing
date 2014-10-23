
class InsParser
  parse: (fname) =>
    file = io.open fname
    sections = {}

    local current_section
    local current_group

    line_no = 0
    for line in file\lines!
      line_no += 1
      continue if @parse_comment line

      if section = @parse_section_header line
        current_section = {}
        print "Section", section
        sections[section] = current_section
        continue

      if group = @parse_group_header line
        assert current_section, "got group without section (#{line_no})"
        -- assert not current_section[group], "section already contains groups `#{group}` (#{line_no})"

        print "Group", group

        current_group = {}
        current_section[group] = current_group
        continue

      key, value = @parse_tuple line
      if key
        print "Tuple", key, value

        assert current_group, "got tuple without group (#{line_no})"
        key = tonumber(key) or key
        -- assert not current_group[key], "group already contains key `#{key}` (#{line_no})"
        current_group[key] = value

    sections

  parse_comment: (line) =>
    line\match "^%s*%;"

  parse_section_header: (line) =>
    line\match "^%s*%.(.-)%s*$"

  parse_group_header: (line) =>
    line\match "^%[(.-)%]%s*$"

  parse_tuple: (line) =>
    line\match "^%s*(.-)=(.-)%s*$"

parser = InsParser!
require("moon").p parser\parse "ins/SC-8850.ins"
