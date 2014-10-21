
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
    bank = midi.bank

    msb = math.floor(bank / 128) % 128
    lsb = bank % 128

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
    midi.bank = @vb.views.bank_msb.value * 128 + @vb.views.bank_lsb.value
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

      @byte_picker "Bank MSB", "bank_msb", refresh
      @byte_picker "Bank LSB", "bank_lsb", refresh
      @byte_picker "Program", "program_no", refresh
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

  byte_picker: (title, id, notifier) =>
    picker = @vb\valuebox {
      :id, :notifier
      min: 0
      max: 128

      tostring: (num) ->
        if num == 0
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
          picker.value = math.min 128, math.max 0, picker.value + 1
      }

      @vb\button {
        text: "Down"
        width: "100%"
        notifier: ->
          picker.value = math.min 128, math.max 0, picker.value - 1
      }
    }

ui = UserInterface!
renoise.app()\show_custom_dialog ui\for_dialog!

