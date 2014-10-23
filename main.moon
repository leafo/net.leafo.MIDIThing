
-- TODO: bank msb/lsb should be 0 based

class UserInterface
  title: "MIDI Thing"
  current_instrument: nil
  loading_instrument: false

  new: =>
    @root = @make_interface!
    @read_instruments!

  for_dialog: =>
    @title, @root

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

  -- set byte pickers from current instrument
  -- TODO: this should be called everytime bank/program are changed in renoise
  copy_from_instrument: =>
    return unless @current_instrument

    print "Copying from instrument"

    midi = @current_instrument.midi_output_properties
    bank = midi.bank - 1

    msb, lsb = if bank >= 0
      math.floor(bank / 128) % 128, bank % 128
    else
      -1, -1

    @loading_instrument = true
    @vb.views.bank_msb.value = msb
    @vb.views.bank_lsb.value = lsb
    @vb.views.program_no.value = midi.program
    @loading_instrument = false

  copy_to_instrument: =>
    return if @loading_instrument
    return unless @current_instrument

    print "Copying to instrument"

    midi = @current_instrument.midi_output_properties
    midi.bank = math.max(0, @vb.views.bank_msb.value) * 128 + @vb.views.bank_lsb.value + 1
    midi.program = @vb.views.program_no.value

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

    ins_loader = @vb\horizontal_aligner {
      mode: "center"
      @vb\button {
        text: "Load .ins file"
        notifier: ->
          fname = renoise.app!\prompt_for_filename_to_read {"ins"}, "Choose .ins file"
          renoise.app!\show_prompt "TODO", "read #{fname}", {"OK"}
      }
    }

    @vb\column {
      margin: 15
      spacing: 15

      instrument_picker
      midi_pickers
      -- ins_loader
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

