page =
  timepicker:
    init: ->
      $('#timepicker').timepicker()
      return

# init page code 
body_id = $('body').attr('id')
if (page[body_id])
  page[ body_id ].init()
