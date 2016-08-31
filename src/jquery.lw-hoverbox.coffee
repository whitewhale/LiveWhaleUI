$ = livewhale?.jQuery || window.jQuery

$.widget 'lw.hoverbox',
  options:
    position:       'top'   # possible options are left, right, top, bottom
    width:          'auto'
    height:         'auto'
    autoOpen:       false
    maxWidth:       null
    maxHeight:      null
    html:           null
    text:           null
    zIndex:         null
    distance:       2
    xpos:           null    # force hoverbox to oper at xpos
    ypos:           null    # force hoverbox to open at ypos
    pointer_width:  11
  _create: ->
    @$body = $('body')

    @element.addClass('lwui-widget lwui-hoverbox')

    # open if autoOpen, otherwise attach click handler
    if (@options.autoOpen)
      @open()
    else
      @_bindOpenHandler()
  positionLeft: ->
    el     = @element
    opts   = @options
    width  = @$hoverbox.outerWidth()
    height = @$hoverbox.outerHeight()

    if (!opts.ypos && (width + opts.pointer_width + opts.distance > el.offset().left))
      @positionTop()
      return @

    xpos = el.offset().left - width - opts.pointer_width - opts.distance
    ypos = if (opts.ypos) then opts.ypos - height / 2 else el.offset().top - height / 2 + el.outerHeight() / 2

    @$hoverbox.addClass('lw_left').css(
      top: ypos,
      left: xpos
    )
    return @
  positionRight: ->
    el     = @element
    opts   = @options
    width  = @$hoverbox.outerWidth()
    height = @$hoverbox.outerHeight()

    if (!opts.ypos && (width + opts.pointer_width + opts.distance > $(window).width() - el.offset().left))
      @positionTop()
      return @

    xpos = el.offset().left + el.outerWidth() + opts.pointer_width + opts.distance
    ypos = if (opts.ypos) then opts.ypos - height / 2 else el.offset().top - height / 2 + el.outerHeight() / 2
    @$hoverbox.addClass('lw_right').css(
      top: ypos,
      left: xpos
    )
    return @
  positionTop: ->
    el        = @element
    opts      = @options
    width     = @$hoverbox.outerWidth()
    height    = @$hoverbox.outerHeight()
    ypos      = el.offset().top - opts.pointer_width - height - opts.distance
    win_width = $(window).width()

    # position on bottom is there's not enough room
    if (height + opts.pointer_width + opts.distance > el.offset().top)
      @positionBottom()
      return @

    # shrink box if if's wider than window width minus 10px gutters
    if (width >= win_width - 20)
      width = win_width - 20
      xpos = 10

      # constrict width and re-calc ypos with new height
      @$hoverbox.width(width)
      height = @$hoverbox.outerHeight()
      ypos = el.offset().top - opts.pointer_width - height - opts.distance

      # the height of the box changed so check again to see if we need to position on bottom
      if (height + opts.pointer_width + opts.distance > el.offset().top)
        @positionBottom()
        return @
    else
      xpos = if (opts.xpos)
        opts.xpos - width / 2
      else
        el.offset().left - width / 2 + el.outerWidth() / 2

      # don't set xpos below 10
      if (xpos < 10)
        xpos = 10

    @$hoverbox.addClass('lw_top').css('top', ypos)

    # set right position if left pos would make box extend beyond the right side of the screen
    if (xpos + width > win_width)
      @$hoverbox.css('right', 10)
    else
      @$hoverbox.css('left', xpos)
    @positionArrow()
    return @
  positionBottom: ->
    el        = @element
    opts      = @options
    width     = @$hoverbox.outerWidth()
    ypos      = el.offset().top + el.outerHeight() + opts.pointer_width + opts.distance
    win_width = $(window).width()

    # to avoid a loop, we don't change to another position if it doesn't fit below element

    if (width >= win_width)
      width = win_width - 20
      xpos = 10
      @$hoverbox.width(width)
    else
      xpos = if (opts.xpos)
        opts.xpos - width / 2
      else
        el.offset().left - width / 2 + el.outerWidth() / 2

      if (xpos < 10)
        xpos = 10

    @$hoverbox.addClass('lw_bottom').css('top', ypos)

    # set right position if left pos would make box extend beyond the right side of the screen
    if (xpos + width > win_width)
      @$hoverbox.css('right', 10)
    else
      @$hoverbox.css('left', xpos)

    @positionArrow()
    return @
  position: ->
    switch (@options.position)
      when 'bottom'
        @positionBottom()
        break
      when 'left'
        @positionLeft()
        break
      when 'right'
        @positionRight()
        break
      else
        @positionTop()
        break
    return @
  positionArrow: ->
    el       = @element
    box_left = parseInt(@$hoverbox.css('left'), 10)
    el_xpos  = el.offset().left + el.outerWidth() / 2
    @$hoverbox.find('.lw_arrow').css('left', el_xpos - box_left - @options.pointer_width / 2)
  append: (content) ->
    @$content.append(content)
  html: (html) ->
    @$content.html(html)
  _initUI: ->
    opts = @options

    @$content = $('<div/>').addClass('lw_hoverbox_content')
    @$pointer = $('<div/>').addClass('lw_arrow')

    @$hoverbox = $('<div/>',
      class: 'lw_hoverbox'
      width: opts.width
      height: opts.height
      css: { display: 'none' }
    )
    .append(@$pointer)
    .append(@$content)
    .appendTo(@$body)
    
    if (opts.maxWidth)
      @$hoverbox.css('max-width', parseInt(opts.maxWidth, 10) + 'px')

    if (opts.maxHeight)
      @$hoverbox.css('max-height', parseInt(opts.maxHeight, 10) + 'px')

    if (opts.zIndex)
      @$hoverbox.css('z-index', opts.zIndex)
    
    # set content
    if (opts.html)
      @$content.html(opts.html)

    @_ui_initialize = true
    return true
  _bindCloseHandler: ->
    that = this

    # handler to destroy instance when hoverbox is closed
    @close_handler = (e) ->
      e.preventDefault()
      $target = $(e.target)

      # don't close hoverbox if click within hoverbox
      if ($target.closest('.lw_hoverbox').length)
        return false

      that.close()

      return true

    # defining handler as an object property allows us to unbind this specific handler
    # we can't use one here instead of bind, because of the case where the click is within hoverbox 
    @$body.bind('click', @close_handler)
  _bindOpenHandler: ->
    that = this

    @open_handler = (e) ->
      e.preventDefault()
      e.stopPropagation()
      that.$body.click()   # body click to close any open hoverboxs
      that.open()
      return true

    @element.one('click', @open_handler)
  open: ->
    opts = @options

    if (!@_ui_initialized) then @_initUI()
    
    @_trigger('beforeOpen', null, this)

    @position()
    @$hoverbox.show()
    @_bindCloseHandler()
    
    @_trigger('open', null, this)
  close: ->
    @$hoverbox.hide()

    # re-bind open handler so it can be opened again if not autoOpen
    if (!@options.autoOpen) then @_bindOpenHandler()
    @$body.unbind('click', @close_handler)

    @_trigger('close', null, this)
  _destroy: (callback) ->
    @element.removeClass('lwui-widget lwui-hoverbox')

    if (@$hoverbox) then @$hoverbox.remove()
    if (@close_handler) then @$body.unbind('click', @close_handler)
    if (@open_handler) then @element.unbind('click', @open_handler)
