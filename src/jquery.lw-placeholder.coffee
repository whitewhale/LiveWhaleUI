$ = livewhale?.jQuery || window.jQuery

input_el = document.createElement('input')
#placeholder_supported = ('placeholder' in input_el)
placeholder_supported = document.createElement('input').placeholder?

console.log placeholder_supported

# only define functional placeholder widget if browser doesn't support placeholder attribute
if (not placeholder_supported)
  widget =
    options:
      placeholder_class: 'placeholder'
    _create: ->
      $el = @element

      #console.log 'using it'

      @visible = false
      $el.focus $.proxy(@hide, this)
      $el.blur $.proxy(@show, this)

      if ($el.val() is '' )
        $el
          .val($el.attr('placeholder'))
          .addClass(@options.placeholder_class)
          @visible = true

      $el.addClass('lw-placeholder')
    hide: ->
      $el = @element
      if ($el.val() is $el.attr('placeholder'))
        $el
          .val('')
          .removeClass(@options.placeholder_class)

        @visible = false
    show: ->
      $el = @element

      if ($el.val() is '')
        $el
          .val($el.attr('placeholder'))
          .addClass(@options.placeholder_class)

        @visible = true

    # make sure placeholder values aren't submitted
    preventPlaceholderSubmit: ->
else
  widget =
    _create: ->
      alert 'wtf'

$.widget 'lw.lwPlaceholder', widget
