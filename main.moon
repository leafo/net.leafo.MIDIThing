
vb = renoise.ViewBuilder!

byte_picker = (title, id, notifier) ->
  picker = vb\valuebox {
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

  vb\column {
    spacing: 1
    vb\text text: title

    picker

    vb\button {
      text: "Up"
      width: "100%"
      notifier: ->
        picker.value = math.min 128, math.max 0, picker.value + 1
    }

    vb\button {
      text: "Down"
      width: "100%"
      notifier: ->
        picker.value = math.min 128, math.max 0, picker.value - 1
    }
  }


update_instruments = ->
  labels = for idx, inst in ipairs renoise.song().instruments
    name = inst.name
    if name == ""
      name = inst.midi_output_properties.device_name

    "#{idx}: #{name}"

  vb.views.instrument_picker.items = labels

local current_instrument
loading_instrument = false

refresh_byte_pickers = ->
  midi = current_instrument.midi_output_properties
  bank = midi.bank

  msb = math.floor(bank / 128) % 128
  lsb = bank % 128

  loading_instrument = true
  vb.views.bank_msb.value = msb
  vb.views.bank_lsb.value = lsb
  vb.views.program_no.value = midi.program
  loading_instrument = false

refresh_instrument = ->
  return if loading_instrument
  print "Refreshing instrument"
  midi = current_instrument.midi_output_properties
  midi.bank = vb.views.bank_msb.value * 128 + vb.views.bank_lsb.value
  midi.program = vb.views.program_no.value


pick_instrument = (i) ->
  current_instrument = if i
    renoise.song().instruments[i]
  else
    renoise.song().selected_instrument

  assert current_instrument, "failed to get instrument"
  refresh_byte_pickers!

instrument_picker = vb\column {
  width: "100%"

  vb\text text: "Instrument"
  vb\popup {
    width: "100%"
    id: "instrument_picker"
    items: {}
    notifier: (idx) ->
      pick_instrument idx
  }
}


midi_pickers = vb\row {
  spacing: 20

  byte_picker "Bank MSB", "bank_msb", refresh_instrument
  byte_picker "Bank LSB", "bank_lsb", refresh_instrument
  byte_picker "Program", "program_no", refresh_instrument
}

ins_loader = vb\horizontal_aligner {
  mode: "center"
  vb\button {
    text: "Load .ins file"
    notifier: ->
      fname = renoise.app!\prompt_for_filename_to_read {"ins"}, "Choose .ins file"
      renoise.app!\show_prompt "TODO", "read #{fname}", {"OK"}
  }
}

content = vb\column {
  margin: 15
  spacing: 15

  instrument_picker
  midi_pickers
  -- ins_loader
}

renoise.app()\show_custom_dialog "MIDI Thing", content
update_instruments!
pick_instrument!

