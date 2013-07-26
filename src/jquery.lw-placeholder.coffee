$ = livewhale?.jQuery || window.jQuery

placeholder_support = 'placeholder' in document.createElement('input')

# only define functional placeholder widget if browser doesn't support placeholder attribute
if (!placeholder_support)
  widget =
    _create: ->
      $el = @element
      pclass = 'placeholder' 

      # set visible status to false
      @visible = false

      # and focus and blur handlers
      $el.focus $.proxy(@clear, this)
      $el.blur $.proxy(@set, this)

      @set
    clear: ->
      $el = @element
      if ($el.origVal() is $el.attr('placeholder'))
        $el
          .val('')
          .removeClass('placeholder')

        @visible = false
    set: ->
      $el = @element

      if ($el.origVal() is '')
        $el
          .val($el.attr('placeholder'))
          .addClass('placeholder')

        @visible = true

  # replace jQuery.fn.val so it returns an empty string if the val and placeholder match
  # another option is to add a submit handler that does the same thing. However, this 
  # breaks when defining additional submit handlers that do things like submit via ajax 
  # because we can't control which handler gets called first
  $.fn.origVal = $.fn.val
  $.fn.val = ->
    $this = $(this)

    # when setter
    # call original val method if setting value
    if(arguments.length > 0) then return $.fn.origVal.apply(this, arguments)

    # when getter 
    # return empty string if val === placeholder, return val otherwise
    val = $.fn.origVal.call(this)
    placeholder = $this.attr('placeholder')
    return if (val is placeholder) then '' else val
  
  # clear placeholder values on page reload 
  $(window).on 'unload', ->
    $('input[placeholder]').each ->
      this.value = ''
      #$(this).val('')
    return true
else
  widget =
    _create: ->

$.widget 'lw.lwPlaceholder', widget
