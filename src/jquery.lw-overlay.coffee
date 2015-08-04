$ = livewhale?.jQuery || window.jQuery

$.widget 'lw.overlay',
  options:
    destroyOnClose:    true
    id:                false
    customClass:       null   # one or more space-separated classes to be added to dialog wrapper
    closeSelector:     ''     # selector for elements whose click should close dialog
    closeButton:       true
    closeOnBodyClick:  false
    backdrop:          true
    autoOpen:          true
    margin:            30
    width:             null
    height:            null
    title:             null,
    footer:            null,
    size:              'medium', # large, medium, small
    zIndex:            null
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

    @$wrapper      = $('<div/ class="lw_element lw_overlay_wrapper"/>')
    @$dialog       = $('<div class="lw_overlay"/>')
    @$contents     = $('<div class="lw_overlay_contents"/>')
    @$content_body = $('<div class="lw_overlay_body"/>').html($el.show()).appendTo(@$contents)
    @$body         = $('body')

    $dialog = @$dialog

    if (opts.backdrop) then @$backdrop = $('<div class="lw_overlay_backdrop"/>')
    
    if (opts.zIndex)
      @$wrapper.css('z-index', parseInt(opts.zIndex, 10) + 10)
      if (opts.backdrop) then @$backdrop.css('z-index', opts.zIndex)

    if (opts.width) then $dialog.css('width', opts.width)
    if (opts.height) then @_setHeight(opts.height)

    this._setSize(opts.size)

    close_selectors = ['.lw_overlay_close']
    if (opts.closeSelector) then close_selectors.push(opts.closeSelector) else []

    # add close button if opted for
    if (opts.closeButton)
      @$dialog.html('<a class="lw_overlay_close_button" href="#">&times;</a>')
      close_selectors.push('.lw_overlay_close_button')

    # add class and id to overlay wrapper
    if (opts.customClass) then @$dialog.addClass(opts.customClass)
    if (opts.id) then @$dialog.attr('id', opts.id)
    
    # don't let clicks within dialog propagate beyond dialog
    @$dialog.click (e) ->
      e.stopPropagation()
      return true

    # close handler for selectors including che 
    if (close_selectors.length)
      @$dialog.on 'click.lw', close_selectors.join(', '), (e) ->
        e.preventDefault()
        that.close()
        return false

    # close when click registered outside of dialog if closeOnBodyClick
    if (this.options.closeOnBodyClick)
      @$wrapper.click ->
        that.close()
        return true

    # put it together
    @$wrapper
      .append( @$dialog.append(@$contents) )
      .appendTo(@$body)

    if (opts.title) then @_renderHeader(opts.title)
    if (opts.footer) then @_renderFooter(opts.footer)

    # reposition dialog on lw resize
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
  _setSize: (size) ->
    sizes =
      large: 'overlay-lg'
      medium: 'overlay-md'
      small: 'overlay-sm'

    # do nothing if size not valid
    if (not size or not sizes[size]) then return

    # remove any existing size classes
    @$dialog.removeClass(sizes.large + ' ' + sizes.medium + ' ' + sizes.small)
    @$dialog.addClass(sizes[size])
  _destroy: ->
    $el = @element

    @$body.removeClass('lw_overlay_open')

    # detach this.element before removing the wrapper
    $el.detach()

    if (@$wrapper)
      @$wrapper.remove()
      @$wrapper = null

    if (@$backdrop)
      @$backdrop.remove()

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

    if (key is 'height')
      @_setHeight(value)

    if (key is 'size')
      @_setSize(value)

    if (key is 'title')
      @_renderHeader(value)

    if (key is 'footer')
      @_renderFooter(value)

    @_super(key, value)
  open: ->
    that = this

    @$wrapper.show()

    if (this.options.backdrop)
      @$backdrop.appendTo(@$body)

    @$body.addClass('lw_overlay_open')
    this._trigger('open')

    return @
  close: ->
    if (@options.destroyOnClose)
      @destroy()
    else
      @$wrapper.hide()
      if (this.options.backdrop) then @$backdrop.detach()
      @$body.removeClass('lw_overlay_open')

    @_trigger('close')
    return @
  html: (content) ->
    @$content_body.html(content)
    return @
  append: (content) ->
    @$content_body.append(content)
    return @
  _renderHeader: (title) ->
    if (not @$header)
      html  = '''
        <div class="lw_overlay_header">
        <button type="button" class="lw_overlay_close" aria-label="Close">×</button>
        <h3></h3>
        </div>
        '''
      # prepend header
      @$header = $(html).prependTo(@$contents)

      # remove the old style close button if it exists
      if (this.options.closeButton) then @$dialog.find('.lw_overlay_close_button').remove()
    @$header.find('> h3').text(title)
    return @
  _renderFooter: (footer) ->
    if (not @$footer)
      html  = '''
        <div class="lw_overlay_footer">
        </div>
        '''
      # prepend header
      @$footer = $(html).appendTo(@$contents)
    @$footer.html(footer)
    return @
  # animatedResize was called sizeTo in the old overlay plugin
  animatedResize: (width, height, callback) ->
    that      = this
    #padding   = @$dialog.outerWidth() - @$dialog.width()

    #if (width)
    #  props.width = width

    #if (height)
    #  props.height = props.height

    # set content wrapper height for fixed height dialog with scrollbar 
    @$contents.height(height)

    # animated resizing of dialog
    @$dialog.animate { width: width, height: height }, 'fast', ->
      if ($.isFunction(callback)) then callback.apply(that)

    return @
