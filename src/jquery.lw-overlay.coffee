$ = livewhale?.jQuery || window.jQuery

$.widget 'lw.overlay',
  options:
    destroyOnClose:    true
    id:                false
    customClass:       null   # one or more space-separated classes to be added to dialog wrapper
    closeSelector:     ''     # selector for elements whose click should close dialog
    closeButton:       true
    closeOnBodyClick:  false
    autoOpen:          true
    margin:            30
    width:             null
    height:            null
    size:              'medium' # large, medium, small
  _create: ->
    $this = $(this)
    that  = this
    opts  = @options
    $el   = @element

    @orig_css =
      display: $el[0].style.display

    @orig_pos =
      parent: $el.parent()
      index: $el.parent().children().index($el)

    @$container = $('<div/ class="lw_element lw_overlay_container"/>')
    @$blackout  = $('<div class="lw_overlay_blackout"/>')
    @$dialog    = $('<div class="lw_overlay"/>')
    @$contents  = $('<div class="lw_overlay_contents"/>')
    @$body      = $('body')
    @$window    = $(window)

    $dialog = @$dialog

    if (opts.width) then $dialog.css('width', opts.width)
    if (opts.height) then @_setHeight(opts.height)

    if (opts.size is 'large') then @$dialog.addClass('overlay-lg')
    if (opts.size is 'small') then @$dialog.addClass('overlay-sm')

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
      .append(@$dialog.append(@$contents.append( $el.show() )))
      .appendTo(@$body)

    # close handler for selectors including che 
    if (close_selectors.length)
      @$container.on 'click.lw', close_selectors.join(', '), (e) ->
        e.preventDefault()
        that.close()
        return false

    # reposition dialog on lw resize
    @$window.bind('resize.lw', $.proxy(@position, @))
    @_trigger('create')

    return true
  _init: ->
    if (@options.autoOpen) then @open()
  _setHeight: (height) ->
    @$dialog.height(height)
    @$contents.height(height)
  _setMaxHeight: (height) ->
    @$dialog.css('max-height', height)
    @$contents.css('max-height', height)
  _destroy: ->
    $el = @element

    @$body.removeClass('lw_overlay_open')
    @$window.unbind('lw')

    # detach this.element before removing the container
    $el.detach()

    if (@$container)
      @$container.remove()
      @$container = null

    # restore original css 
    $el.css(@orig_css)

    # restore original position
    if (@orig_pos.parent.length)
      $next = @orig_pos.parent.children().eq( @orig_pos.index )
      # Don't place the dialog next to itself 
      if ($next.length && $next[0] isnt $el[0])
        $next.before($el)
      else
        @orig_pos.parent.append($el)

    return
  _setOption: (key, value) ->
    if (key is 'width')
      @$dialog.css(key, value)
      @position()

    if (key is 'height')
      @_setHeight(value)
      @position()

    if (key is 'maxWidth')
      @$dialog.css('max-width', value)
    if (key is 'maxHeight')
      @_setMaxHeight(value)
    if (key is 'minWidth')
      @$dialog.css('min-width', value)
    if (key is 'minHeight')
      @$dialog.css('min-height', value)
  open: ->
    that = this

    @$container.show()
    @$body.addClass('lw_overlay_open')
    @position()
    this._trigger('open')

    # handler for closing when clicking outsite dialog box
    if (@options.closeOnBodyClick)
      @$blackout.one 'click', (e) ->
        e.preventDefault()
        that.close()
        return false
    return @
  close: ->
    if (@options.destroyOnClose)
      @destroy()
    else
      @$container.hide()
      @$body.removeClass('lw_overlay_open')

    @_trigger('close')
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
    dialog_height = @$dialog.outerHeight() + (@options.margin * 2)
    win_height    = @$window.height()

    height = if (dialog_height > win_height) then dialog_height else win_height
    @$blackout.height(height)

    return true
  # animatedResize was called sizeTo in the old overlay plugin
  animatedResize: (width, height, callback) ->
    that      = this
    #padding   = @$dialog.outerWidth() - @$dialog.width()

    #if (width)
    #  props.width = width

    #if (height)
    #  props.height = props.height

      # set content container height for fixed height dialog with scrollbar 
    @$contents.height(height);

    # animated resizing of dialog
    @$dialog.animate { width: width, height: height }, 'fast', ->
      if ($.isFunction(callback)) then callback.apply(that)

    return @
