$ = livewhale.jQuery || window.jQuery

$.widget 'lw.lwDialog',
  options:
    'id':          false
    customClass:   null # one or more space-separated classes to be added to dialog wrapper
    fadeIn:        100
    sizeTo:        300
    closeButton:   true
    closeClasses:  [] # elements with these classes will close dialog on click
    autoOpen:      true
  _create: ->
    $this = $(this)
    that  = this
    opts  = @options
    el    = @element

    @$contents = $ '<div>',
      'class': 'lw_overlay_contents'

    @$dialog = $ '<div>',
      'class': 'lw_overlay'

    # add close button if opted for
    if (opts.closeButton)
      @$dialog.html('<a class="lw_overlay_close_button" href="#">&times;</a>')
      opts.closeClasses.push('.lw_overlay_close_button')

    # add class and id to overlay wrapper
    if (opts.customClass) then @$dialog.addClass(opts.customClass)
    if (opts.id) then @$dialog.attr('id', opts.id)

    @$blackout = $ '<div/>',
      'class': 'lw_overlay_blackout'

    @$container = $ '<div>',
      'class': 'lw_element lw_overlay_container'
      .append(@$blackout)
      .append(@$dialog
      .append(@$contents.append(el)))
      .appendTo($('body'))

    # set close handler for classes in opts.closeClasses 
    @$container.on 'click', opts.closeClasses.join(','), (evt) ->
      evt.preventDefault()
      that.destroy() # remove it
      return false # and cancel the click

    @position() # and position the overlay
  _init: ->
    if (@options.autoOpen)
      @open()
  open: ->
    # return right away if already open
    return false if (@_isOpen)
    @_isOpen = true

    that = this
    opts = @options

    # fade in the blackout, then the overlay
    @$blackout.fadeTo opts.fadeIn / 2, 1, ->
      that.$dialog.fadeTo opts.fadeIn / 2, 1, ->
        that._trigger('open')
  close: ->
    @$blackout.hide()
    @$dialog.hide()

    @_isOpen = false
  html: (content) ->
    @$contents.html(content); # set HTML
    @position(); # re-position the overlay
  append: (content) ->
    @$contents.append(content); # set HTML
    #@position();                # re-position the overlay
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
  sizeTo: (width, height, callback) ->
    that = this
    scrolltop = $(document).scrollTop()
    offset = Math.max(@$dialog.offset().top - (height - @$dialog.height()) / 2, scrolltop + 10)

    @$dialog.animate(
      width: width
      height: height
      top: offset
    , @options.sizeTo, ->
      # call callback
      if ($.isFunction(callback))
        callback.apply(that)
    )
  remove: (callback) ->
    that = this

    # remove the overlay if it exists 
    if (@$container)
      @$container.focusout().fadeTo @$dialog.fadeIn / 2, 0, ->
        that.$container.remove() # remove the overlay
        if ($.isFunction(callback))
          callback.apply(null)
  #sizeTo: @size, # alias to for BC with original overlay plugin
  _setOption: (key, value) ->
    # In jQuery UI 1.8, you have to manually invoke the _setOption method from the base widget
    $.Widget.prototype._setOption.apply(this, arguments)
  _destroy: (callback) ->
    @remove()
