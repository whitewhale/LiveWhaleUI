$ = livewhale?.jQuery || window.jQuery

$.widget 'lw.overlay',
  options:
    destroyOnClose:    true
    id:                false
    customClass:       null   # one or more space-separated classes to be added to dialog wrapper
    closeSelector:     ''     # selector for elements whose click should close dialog
    closeButton:       true
    closeOnBodyClick:  false,
    autoOpen:          true
    maxWidth:          '90%'
    maxHeight:         null
    minWidth:          null
    minHeight:         null
    width:             null
    height:            null
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

    @$container = $('<div/ class = "lw_element lw_overlay_container"/>')
    @$blackout  = $('<div class  = "lw_overlay_blackout"/>')
    @$dialog    = $('<div class  = "lw_overlay"/>')
    @$contents  = $('<div class  = "lw_overlay_contents"/>')

    $dialog = @$dialog

    if (opts.width) then $dialog.css('width', opts.width)
    if (opts.height) then @_setHeight(opts.height)
    if (opts.maxWidth) then $dialog.css('max-width', opts.maxWidth)
    if (opts.maxHeight) then @_setMaxHeight(opts.maxHeight)
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
      .append(@$dialog.append(@$contents.append( $el.show() )))
      .appendTo($('body'))

    # close handler for selectors including che 
    if (close_selectors.length)
      @$container.on 'click.lw', close_selectors.join(', '), (e) ->
        e.preventDefault()
        that.close()
        return false

    # reposition dialog on lw resize
    $(window).bind('resize.lw', $.proxy(@position, @))

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

    $(window).unbind('lw')

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
    $window = $(window)

    # if there's no offset specified, set the overlay near the top of the window/
    ycoord = Math.max(($window.height() - @$dialog.outerHeight()) / 4, 20)
    xcoord = ($window.width() - @$dialog.outerWidth()) / 2
    
    @$dialog.css
      top: $(document).scrollTop() + ycoord
      left: xcoord

    return true
  # animatedResize was called sizeTo in the old overlay plugin
  animatedResize: (width, height, callback) ->
    that      = this
    scrolltop = $(document).scrollTop()
    offset    = @$dialog.offset()
    props     = {}
    padding   = @$dialog.outerWidth() - @$dialog.width()

    if (width)
      props.left = ($(window).width() - width - padding) / 2
      props.width = width

    if (height)
      props.height = height
      props.top = Math.max(offset.top - (height - @$dialog.height()) / 4, scrolltop + 10)

      # set content container height for fixed height dialog with scrollbar 
      @$contents.animate({ height: height }, 'fast')

    # animated resizing of dialog
    @$dialog.animate props, 'fast', ->
      if ($.isFunction(callback)) then callback.apply(that)

    return @
