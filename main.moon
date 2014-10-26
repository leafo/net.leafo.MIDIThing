
class UserInterface
  title: "MIDI Thing"
  current_instrument: nil
  loading_instrument: false

  modules: {
    "ins.Korg-NX5R"
    "ins.SC-8850"
  }

  new: =>
    @root = @make_interface!
    @read_instruments!
    @load_modules!

  for_dialog: =>
    @title, @root

  load_modules: =>
    @raw_modules = {}
    names = {}
    for m in *@modules
      for name, mod in pairs require m
        table.insert names, name
        table.insert @raw_modules, mod

    @vb.views.module_picker.items = {"", unpack names}

  -- read instruments from renoise, update dropdown
  -- TODO: this should be called everytime instruments are changed in renoise
  read_instruments: =>
    labels = for idx, inst in ipairs renoise.song().instruments
      name = inst.name
      if name == ""
        name = inst.midi_output_properties.device_name

      "#{idx}: #{name}"

    @vb.views.instrument_picker.items = labels
    @pick_instrument!

  pick_instrument: (i) =>
    @current_instrument = if i
      renoise.song().instruments[i]
    else
      renoise.song().selected_instrument

    @copy_from_instrument!

  set_bank_program: (bank, program) =>
    msb, lsb = if bank >= 0
      math.floor(bank / 128) % 128, bank % 128
    else
      -1, -1

    @loading_instrument = true
    @vb.views.bank_msb.value = msb
    @vb.views.bank_lsb.value = lsb
    @vb.views.program_no.value = program + 1 -- uses 1 based selector
    @loading_instrument = false

  -- set byte pickers from current instrument
  -- TODO: this should be called everytime bank/program are changed in renoise
  copy_from_instrument: =>
    return unless @current_instrument

    print "Copying from instrument"

    midi = @current_instrument.midi_output_properties
    bank = midi.bank - 1

    @set_bank_program bank, midi.program - 1

  copy_to_instrument: =>
    return if @loading_instrument
    return unless @current_instrument

    print "Copying to instrument"

    midi = @current_instrument.midi_output_properties
    midi.bank = math.max(0, @vb.views.bank_msb.value) * 128 + @vb.views.bank_lsb.value + 1
    midi.program = @vb.views.program_no.value

  choose_module: (idx) =>
    if idx == 1
      @current_module = nil

    @current_module = @raw_modules[idx - 1]

    bank_tuples = [{i.name, i} for _, i in pairs @current_module]
    table.sort bank_tuples, (a,b) -> a[1] < b[1]

    local current_bank
    local program_tuples

    if @module_sub_pickers
      @vb.views.module_picker_outer\remove_child @module_sub_pickers

    program_picker = @vb\popup {
      width: "100%"
      items: {}
      notifier: (i) ->
        program = program_tuples[i][1]
        bank = current_bank.bank
        @set_bank_program bank, program
        @copy_to_instrument!
    }

    @module_sub_pickers = @vb\column {
      width: "100%"

      @vb\popup {
        width: "100%"
        items: [t[1] for t in *bank_tuples]
        notifier: (i) ->
          current_bank = bank_tuples[i][2]
          program_tuples = [{k,v} for k,v in pairs current_bank.instruments]
          table.sort program_tuples, (a,b) -> a[1] < b[1]
          program_picker.items = [t[2] for t in *program_tuples]
      }

      program_picker
    }

    @vb.views.module_picker_outer\add_child @module_sub_pickers

  make_interface: =>
    @vb = renoise.ViewBuilder!
    instrument_picker = @vb\column {
      width: "100%"

      @vb\text text: "Instrument"
      @vb\popup {
        width: "100%"
        id: "instrument_picker"
        items: {}
        notifier: (idx) ->
          @pick_instrument idx
      }
    }

    refresh = @\copy_to_instrument

    midi_pickers = @vb\row {
      spacing: 20

      @byte_picker {
        title: "Bank MSB"
        id: "bank_msb"
        notifier: refresh
        min: -1
        max: 127
      }

      @byte_picker {
        title: "Bank LSB"
        id: "bank_lsb"
        notifier: refresh
        min: -1
        max: 127
      }

      @byte_picker {
        title: "Program"
        id: "program_no"
        notifier: refresh
      }
    }

    -- TODO: probably not going to do this
    ins_loader = @vb\horizontal_aligner {
      mode: "center"
      @vb\button {
        text: "Load .ins file"
        notifier: ->
          fname = renoise.app!\prompt_for_filename_to_read {"ins"}, "Choose .ins file"
          renoise.app!\show_prompt "TODO", "read #{fname}", {"OK"}
      }
    }

    module_picker = @vb\column {
      width: "100%"
      id: "module_picker_outer"

      @vb\text text: "MIDI Module"
      @vb\popup {
        width: "100%"
        id: "module_picker"
        items: {}
        notifier: (idx) ->
          @choose_module idx
      }

    }

    @vb\column {
      margin: 15
      spacing: 15

      instrument_picker
      midi_pickers
      module_picker
    }

  byte_picker: (opts) =>
    {:title, :id, :notifier} = opts
    max = opts.max or 128
    min = opts.min or 0

    picker = @vb\valuebox {
      :id, :notifier, :min, :max

      tostring: (num) ->
        if num == min
          "Off"
        else
          tostring num

      tonumber: (str) ->
        tonumber(str) or 0

    }

    @vb\column {
      spacing: 1
      @vb\text text: title

      picker

      @vb\button {
        text: "Up"
        width: "100%"
        notifier: ->
          picker.value = math.min max, math.max min, picker.value + 1
      }

      @vb\button {
        text: "Down"
        width: "100%"
        notifier: ->
          picker.value = math.min max, math.max min, picker.value - 1
      }
    }

ui = UserInterface!
renoise.app()\show_custom_dialog ui\for_dialog!

