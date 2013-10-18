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
  overlay:
    init: ->
      $('#overlay_open').click ->
        $('#overlay_content').overlay()
        return true
      return
  popover:
    init: ->
      $('.open_top').popover
        position: 'top'
        html: '<p>Hello World!</p>'

      $('.open_bottom').popover
        position: 'bottom'
        html: '<p>Hello World!</p>'
      
      $('.open_left').popover
        position: 'left'
        html: '<p>Hello World!</p>'
      
      $right = $('.open_right').popover
        position: 'right'
        html: '<p>Hello World!</p>'
        close: ->
          $(this).popover('destroy')

# init page code
# each page should have a body id that matches a key in page object 
body_id = $('body').attr('id')
if (page[body_id]) then page[body_id].init()
