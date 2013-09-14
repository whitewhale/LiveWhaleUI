$ = livewhale?.jQuery || window.jQuery

$.widget 'lw.overlay',
  options:
    destroyOnClose: true
    id:             false
    customClass:    null # one or more space-separated classes to be added to dialog wrapper
    closeSelector:  ''   # selector for elements whose click should close dialog
    closeButton:    true
    autoOpen:       true
    maxWidth:       '90%'
    maxHeight:      null
    minWidth:       null
    minHeight:      null
    width:          null
    height:         null
  _create: ->
    $this = $(this)
    that  = this
    opts  = @options
    $el   = @element

    @$container = $('<div/ class = "lw_element lw_overlay_container"/>')
    @$blackout  = $('<div class  = "lw_overlay_blackout"/>')
    @$dialog    = $('<div class  = "lw_overlay"/>')
    @$contents  = $('<div class  = "lw_overlay_contents"/>')

    $dialog = @$dialog

    if (opts.width) then $dialog.css('width', opts.width)
    if (opts.height) then $dialog.css('height', opts.height)
    if (opts.maxWidth) then $dialog.css('max-width', opts.maxWidth)
    if (opts.maxHeight) then $dialog.css('max-height', opts.maxHeight)
    if (opts.minWidth) then $dialog.css('min-width', opts.minWidth)
    if (opts.minHeight) then $dialog.css('min-height', opts.minHeight)

    close_selectors = []
    if (opts.closeSelector) then close_selectors.push(opts.closeSelector) else []

    # add close button if opted for
    if (opts.closeButton)
      @$dialog.html('<a class="lw_overlay_close_button" href="#">&times;</a>')
      close_selectors.push('.lw_overlay_close_button')

    # add class and id to overlay wrapper
    if (opts.customClass) then @$dialog.addClass(opts.customClass)
    if (opts.id) then @$dialog.attr('id', opts.id)

    # put it together
    @$container
      .append(@$blackout)
      .append(@$dialog.append(@$contents.append($el)))
      .appendTo($('body'))

    # close handler for selectors including che 
    if (close_selectors.length)
      @$container.on 'click.lw', close_selectors.join(', '), (e) ->
        e.preventDefault()
        that.close()
        return false

    $(window).bind('resize.lw', $.proxy(@position, @))

    @open()
    @_trigger('create')
    return true
  _init: ->
    if (@options.autoOpen) then @open()
  destroy: ->
    $(window).unbind('lw')
    return
  _setOption: (key, value) ->
    if (key is 'width' or key is 'height')
      @$dialog.css(key, value)

    if (key is 'maxWidth')
      @$dialog.css('max-width', value)
    if (key is 'maxHeight')
      @$dialog.css('max-height', value)
    if (key is 'minWidth')
      @$dialog.css('min-width', value)
    if (key is 'minHeight')
      @$dialog.css('min-height', value)
  open: ->
    @$container.show()
    @position()
    this._trigger('open')
  close: ->
    @_trigger('close')

    if (@options.destroyOnClose)
      # not sure why, but this implicitly calls @destroy. I tried calling @destroy here, 
      # and removing the container from _destroy(), but that caused an infinite loop
      @$container.remove()
    else
      @$container.hide()
    return @
  html: (content) ->
    @$contents.html(content)
    @position()
    return @
  append: (content) ->
    @$contents.append(content)
    @position()
    return @
  # update the overlay's position
  position: ->
    $window = $(window)


    # if there's no offset specified, set the overlay near the top of the window/
    ycoord = Math.max(($window.height() - @$dialog.outerHeight()) / 4, 20)
    xcoord = ($window.width() - @$dialog.outerWidth()) / 2
    
    @$dialog.css
      top: $(document).scrollTop() + ycoord
      left: xcoord

    return true
