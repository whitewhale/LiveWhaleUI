$ = livewhale?.jQuery || window.jQuery

$.widget 'lw.overlay',
  options:
    id:            false
    customClass:   null # one or more space-separated classes to be added to dialog wrapper
    closeClass:    ''   # elements with these classes will close dialog on click
    closeButton:   true
    autoOpen:      true
    minWidth:      null
    minHeight:     null
    maxWidth:      null
    maxHeight:     null
    width:         null
    fadeIn:        100
  _create: ->
    $this = $(this)
    that  = this
    opts  = @options
    $el   = @element

    @$container = $('<div/ class = "lw_element lw_overlay_container"/>')
    @$blackout  = $('<div class  = "lw_overlay_blackout"/>')
    @$dialog    = $('<div class  = "lw_overlay"/>')
    @$contents  = $('<div class  = "lw_overlay_contents"/>')

    close_classes = if (opts.closeClass) then opts.classClass.split(' ') else []

    # add close button if opted for
    if (opts.closeButton)
      @$dialog.html('<a class="lw_overlay_close_button" href="#">&times;</a>')
      close_classes.push('.lw_overlay_close_button')

    # add class and id to overlay wrapper
    if (opts.customClass) then @$dialog.addClass(opts.customClass)
    if (opts.id) then @$dialog.attr('id', opts.id)

    # put it together
    @$container
      .append(@$blackout)
      .append(@$dialog.append(@$contents.append($el)))
      .appendTo($('body'))

    # close handler for classes in opts.closeClass 
    if (close_classes.length)
      @$container.on 'click', close_classes.join(' '), (e) ->
        e.preventDefault()
        that.close()
        return false

    @open()
    @position()
    @_trigger('create')
    return true
  _destroy: ->
    @$container.remove()
  _init: ->
    if (@options.autoOpen) then @open()
  open: ->
    @$container.show()
    this._trigger('open')
  close: () ->
    @$container.hide()
    @_trigger('close')
  html: (content) ->
    @$contents.html(content)
    @position()
  append: (content) ->
    @$contents.append(content)
    @position()
  # update the overlay's position
  position: (offset) ->
    # clear the height and width
    @$dialog.removeAttr('style')

    # if there's no offset specified, set the overlay near the top of the window/
    offset = offset || Math.max(($(window).height() - @$dialog.outerHeight()) / 4, 10)

    @$dialog.css
      top: $(document).scrollTop() + offset

    # and fix its width if not fixed
    @$dialog.width(@$dialog.width())
