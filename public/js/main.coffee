page =
  timepicker:
    init: ->
      $picker = $('#picker').timepicker()
      
      $('#format_toggle').click (e) ->
        e.preventDefault()

        show24 = if ($picker.timepicker('option', 'show24Hours')) then false else true

        console.log 'is 24:' + show24

        format = $picker.timepicker 'option', 'show24Hours', show24

        return true

      return

# init page code
# each page should have a body id that matches a key in page object 
body_id = $('body').attr('id')
if (page[body_id])
  page[ body_id ].init()
