$ = livewhale?.jQuery || window.jQuery

$.widget 'lw.hoverbox',
  options:
    position:   'top'   # possible options are left, right, top, bottom
    width:      'auto'
    height:     'auto'
    autoOpen:   false
    maxWidth:   null
    maxHeight:  null
    html:       null
    text:       null
    zIndex:     null
    distance:   2
    xpos:       null    # force hoverbox to oper at xpos
    ypos:       null    # force hoverbox to open at ypos
  _create: ->
    @$body = $('body')

    @element.addClass('lwui-widget lwui-hoverbox')

    # open if autoOpen, otherwise attach click handler
    if (@options.autoOpen)
      @open()
    else
      @_bindOpenHandler()
  position: ->
    el             = @element
    opts           = @options
    el_offset      = el.offset()
    adjustment     = opts.distance # 10 is the number of pixels in pointer png beyond tip
    pointer_width  = 11

    pos = opts.position || 'top'

    # switch to opposite position if not room enought at client specified location
    # this is not tested
    if ('top' is pos && (@$hoverbox.outerHeight() + pointer_width + adjustment) > el_offset.top)
      pos = 'bottom'
    else if ('bottom' is pos && (@$hoverbox.outerHeight() + pointer_width + adjustment) > el_offset.bottom)
      pos = 'top'
    else if ('left' is pos && (@$hoverbox.outerWidth() + pointer_width + adjustment > el_offset.left))
      pos = 'right'
    else if ('right' is pos && (@$hoverbox.outerWidth() + pointer_width + adjustment > $(window).width() - el_offset.left))
      pos = 'left'

    switch (opts.position)
      when 'top'
        ypos = el_offset.top - pointer_width - @$hoverbox.outerHeight() - adjustment
        xpos = if (opts.xpos)
          opts.xpos - @$hoverbox.outerWidth() / 2
        else
          el_offset.left - @$hoverbox.outerWidth() / 2 + el.outerWidth() / 2
        break
      when 'bottom'
        ypos = el_offset.top + el.outerHeight() + pointer_width + adjustment
        xpos = if (opts.xpos)
          opts.xpos - @$hoverbox.outerWidth() / 2
        else
          el_offset.left - @$hoverbox.outerWidth() / 2 + el.outerWidth() / 2
        break
      when 'left'
        ypos = if (opts.ypos)
          opts.ypos - @$hoverbox.outerHeight() / 2
        else
          el_offset.top - @$hoverbox.outerHeight() / 2 + el.outerHeight() / 2
        xpos = el_offset.left - @$hoverbox.outerWidth() - pointer_width - adjustment
        break
      when 'right'
        ypos = if (opts.ypos)
          opts.ypos - @$hoverbox.outerHeight() / 2
        else
          el_offset.top - @$hoverbox.outerHeight() / 2 + el.outerHeight() / 2

        xpos = el_offset.left + el.outerWidth() + pointer_width + adjustment
        break
      else
        break

    # position hoverbox
    @$hoverbox.css
      top: ypos,
      left: xpos
  append: (content) ->
    @$content.append(content)
  html: (html) ->
    @$content.html(html)
  _initUI: ->
    opts = @options

    @$content = $('<div/>').addClass('lw_hoverbox_content')
    @$pointer = $('<div/>').addClass('lw_arrow')

    @$hoverbox = $('<div/>',
      class: 'lw_hoverbox lw_' + opts.position
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
