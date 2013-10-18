$ = livewhale?.jQuery || window.jQuery

$.widget 'lw.popover',
  options:
    position:   'top'   # possible options are left, right, top, bottom
    width:      'auto'
    height:     'auto'
    autoOpen:   false
    maxWidth:   null
    maxHeight:  null
    html:       null
    text:       null
    distance:   5
    xpos:       null    # force popover to oper at xpos
    ypos:       null    # force popover to open at ypos
  _create: ->
    @$body = $('body')

    # open if autoOpen, otherwise attach click handler
    if (@options.autoOpen)
      @open()
    else
      @_bindOpenHandler()

  position: ->
    el             = @element
    opts           = @options
    el_offset      = el.offset()
    adjustment     = 10 - opts.distance # 10 is the number of pixels in pointer png beyond tip
    pointer_width  = 22
    pointer_height = 22

    pos = opts.position || 'top'

    # switch to opposite position if not room enought at client specified location
    # this is not tested
    if ('top' is pos && (@$popover.outerHeight() + pointer_height + adjustment) > el_offset.top)
      pos = 'bottom'
    else if ('bottom' is pos && (@$popover.outerHeight() + pointer_height + adjustment) > el_offset.bottom)
      pos = 'top'
    else if ('left' is pos && (@$popover.outerWidth() + pointer_width + adjustment > el_offset.left))
      pos = 'right'
    else if ('right' is pos && (@$popover.outerWidth() + pointer_width + adjustment > $(window).width() - el_offset.left))
      pos = 'left'

    switch (opts.position)
      when 'top'
        ypos = el_offset.top - pointer_height - @$popover.outerHeight() + adjustment
        xpos = if (opts.xpos)
          opts.xpos - @$popover.outerWidth() / 2
        else
          el_offset.left - @$popover.outerWidth() / 2 + el.outerWidth() / 2

        pointer_xpos = @$popover.outerWidth() / 2 - pointer_width / 2
        pointer_ypos = @$popover.outerHeight() - 2
        break
      when 'bottom'
        ypos = el_offset.top + el.outerHeight() + pointer_height - adjustment
        xpos = if (opts.xpos)
          opts.xpos - @$popover.outerWidth() / 2
        else
          el_offset.left - @$popover.outerWidth() / 2 + el.outerWidth() / 2

        pointer_xpos = @$popover.outerWidth() / 2 - pointer_width / 2
        pointer_ypos = 0 - pointer_width
        break
      when 'left'
        ypos = if (opts.ypos)
          opts.ypos - @$popover.outerHeight() / 2
        else
          el_offset.top - @$popover.outerHeight() / 2 + el.outerHeight() / 2
        xpos = el_offset.left - @$popover.outerWidth() - pointer_width + adjustment
        pointer_xpos = @$popover.outerWidth() - 2
        pointer_ypos = @$popover.outerHeight() / 2 - pointer_height / 2
        break
      when 'right'
        ypos = if (opts.ypos)
          opts.ypos - @$popover.outerHeight() / 2
        else
          el_offset.top - @$popover.outerHeight() / 2 + el.outerHeight() / 2

        xpos = el_offset.left + el.outerWidth() + pointer_width - adjustment
        pointer_xpos = 0 - pointer_width
        pointer_ypos = @$popover.outerHeight() / 2 - pointer_height / 2
        break
      else
        break

    # position pointer
    @$pointer.css
      top: pointer_ypos,
      left: pointer_xpos

    # position popover
    @$popover.css
      top: ypos,
      left: xpos
  append: (el) ->
    @$content.append(el)
  _initUI: ->
    opts = @options

    @$content = $('<div/>').addClass('lw_popover_content')
    @$pointer = $('<div/>').addClass('lw_popover_pointer')

    @$popover = $('<div/>',
      class: 'lw_popover lw_popover_pos_' + opts.position
      width: opts.width
      height: opts.height
      css: { display: 'none' }
    )
    .append(@$pointer)
    .append(@$content)
    .appendTo(@$body)
    
    if (opts.maxWidth)
      @$popover.css('max-width', parseInt(opts.maxWidth, 10) + 'px')

    if (opts.maxHeight)
      @$popover.css('max-height', parseInt(opts.maxHeight, 10) + 'px')

    @_ui_initialized = true
    return true
  _bindCloseHandler: ->
    that = this

    # handler to destroy instance when popover is closed
    @close_handler = (e) ->
      e.preventDefault()
      $target = $(e.target)

      # don't close popover if click within popover
      if ($target.closest('.lw_popover').length)
        return false

      that.close()

      return true

    # defining handler as an object property allows us to unbind this specific handler
    # we can't use one here instead of bind, because of the case where the click is within popover 
    @$body.bind('click', @close_handler)
  _bindOpenHandler: ->
    that = this

    @open_handler = (e) ->
      e.preventDefault()
      e.stopPropagation()
      that.$body.click()   # body click to close any open popovers
      that.open()
      return true

    @element.one('click', @open_handler)
  open: ->
    opts = @options

    if (!@_ui_initialized) then @_initUI()

    # set content
    if (opts.html) then @$content.html(opts.html)

    @position()
    @$popover.show()
    @_bindCloseHandler()
  close: ->
    @$popover.hide()

    # re-bind open handler so it can be opened again if not autoOpen
    if (!@options.autoOpen) then @_bindOpenHandler()
    @$body.unbind('click', @close_handler)

    @_trigger('close')
  _destroy: (callback) ->
    if (@$popover) then @$popover.remove()
    if (@close_handler) then @$body.unbind('click', @close_handler)
    if (@open_handler) then @element.unbind('click', @open_handler)
