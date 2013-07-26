$ = livewhale.jQuery || window.jQuery

$.widget 'lw.lwPopover',
  options:
    position:   'top'   # possible options are left, right, top, bottom
    width:      'auto'
    height:     'auto'
    autoOpen:   true
    maxWidth:   null
    maxHeight:  null
    html:       null
    text:       null
    distance:   5
    xpos:       null    # force popover to oper at xpos
    ypos:       null    # force popover to open at ypos
  _create: ->
    that  = this
    el    = @element
    opts  = @options
    $body = $('body')
    coords

    @$content = $('<div/>').addClass('lw_popover_content')
    @$pointer = $('<div/>').addClass('lw_popover_pointer')

    @$popover = $('<div/>',
      class: 'lw_popover lw_hidden lw_popover_pos_' + opts.position
      width: opts.width
      height: opts.height
    )
    .append(@$pointer)
    .append(@$content)
    .appendTo($body)

    if (opts.maxWidth)
      @$popover.css('max-width', parseInt(opts.maxWidth, 10) + 'px')

    if (opts.maxHeight)
      @$popover.css('max-height', parseInt(opts.maxHeight, 10) + 'px')

    # set content
    if (opts.html) then @$content.html(opts.html)

    # position and show
    if (opts.autoOpen?) then @open()

    # for filtering click that initiated plugin creation
    @first_click = true

    # handler to destroy instance when popover is closed
    @close_handler = (e) ->
      $target = $(e.target)

      # don't close popover if click within popover
      if ($target.closest('.lw_popover').length)
        return false

      # also don't close on the first click in which the target element is the same as the 
      # plugin's element.  we need to do this because the plugin is designed to be used in 
      # conjunction with event delegation, where the plugin is created on an item the user 
      # clicks.  If we don't do the following, the click that creates the plugin will bubble 
      # up to the body element and trigger the body click handler we define below which 
      # destroys the plugin.
      if (that.first_click && $target.get(0) is el.get(0))
        that.first_click = false
        return false

      e.preventDefault()
      that.close()

      return true

    # defining handler as an object property allows us to unbind this specific handler
    $body.bind('click', @close_handler)
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
  open: -> 
    @position()
    @$popover.removeClass('lw_hidden')
  close: -> 
    @_trigger('close')
    @destroy()
  _destroy: (callback) -> 
    # clean up
    @$popover.remove()
    $('body').unbind('click', this.close_handler)
