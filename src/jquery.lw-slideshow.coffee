$.widget 'lw.slideshow',
  options:
    fluidHeight: true
    controlPlacement: 'append'
    customClass: null
  _create: ->
    $el    = @element
    opts   = @options
    total  = $el.children().length
    that   = this
    height = 0
    width  = 0
    
    # don't do anything if 1 or no slides 
    if (total <= 1) then return false

    @$wrapper  = $el.wrap('<div class="lw_slider_wrapper" />').parent()
    @$controls = $controls = $(@getControls(total))
    @$prev     = $controls.find('.lw_slider_prev')
    @$next     = $controls.find('.lw_slider_next')
    @$current  = $el.children().eq(0)
    @$previous = null

    # attach controls
    if ('prepend' is opts.controlPlacement)
      @$controls.prependTo(@$wrapper)
    else
      @$controls.appendTo(@$wrapper)

    $el.addClass('lw_slider')
    .children()
      .addClass('lw_slider_slide')

    # add custom class if any
    if (opts.customClass) then $el.addClass(opts.customClass)

    # handler for scroll links 
    @$controls.on 'click', 'a', (evt) ->
      evt.preventDefault()
      $target = $(evt.target)

      # do nothing if the control is disabled
      if ($target.is('.lw_disabled')) then return false

      # if it's the "next" link, otherwise it's a previous link
      if ($target.is('.lw_slider_next')) then that.next()
      if ($target.is('.lw_slider_prev')) then that.prev()

      return true

    # if the first item has an image, wait for image to load before showing slide
    $first_img = $el.children().eq(0).find('img')
    if ($first_img.length)
      $('<img/>').load((evt) ->
        that.showSlide()
        that.$wrapper.width($first_img.width())
      ).attr('src', $first_img.attr('src'))
    else
      @showSlide()

    return true
  _setOption: (key, value) ->
    # In jQuery UI 1.8, you have to manually invoke the _setOption method from the base widget
    $.Widget.prototype._setOption.apply(this, arguments)
  _destroy: (callback) ->
    # destroy removes the slideshow completely, rather than restoring markup to original state
    # we may want to re-evalute this later, but it simplifies its usage with current code
    @$wrapper.remove()
  next: ->
    @$previous = @$current
    @$current = @$current.next()
    @showSlide()
  prev: ->
    @$previous = @$current
    @$current = @$current.prev()
    @showSlide()
  showSlide: ->
    $el          = @element
    $slide       = @$current
    that         = this
    height       = $el.height()     # current height
    targetHeight = $slide.height()  # the height of the slide
    width        = $el.width()      # current width
    targetWidth  = $slide.width()   # the width of the slide

    # return right away if no slide set in data
    if (!$slide || !$slide.length) then return false

    @$prev.addClass('lw_disabled')
    @$next.addClass('lw_disabled')

    # update count in controlls
    @$controls.find('.lw_slider_count_current').html($slide.index() + 1)

    $slide
      .stop() # stop any animation on the slideshow
      .children('.lw_slider_slide').stop().css('z-index', 0); # and its children straightaway

    $slide.css { zIndex: '100' }

    # fade in the slide
    $slide.fadeTo 100, 1, ->
      if (that.$previous) then that.$previous.css('z-index', 0)
      # hide siblings 
      $slide.siblings('.lw_slider_slide').css('opacity', 0)
      # toggle the previous control state
      that.$prev.toggleClass('lw_disabled', !$slide.prev('.lw_slider_slide').length)
      # toggle the next control state
      that.$next.toggleClass('lw_disabled', !$slide.next('.lw_slider_slide').length)

    # adjust wrapper width if different
    if (@$wrapper.width() isnt $slide.width()) then @$wrapper.width($slide.width())

    if (@options.fluidHeight)
      # shrink the slideshow
      if (height > targetHeight or width > targetWidth)
        $el.animate(
          'height': targetHeight
          'width': targetWidth
        , 300)
      # grow the slideshow
      if (height < targetHeight or width < targetWidth)
        $el.animate(
          'height': targetHeight
          'width': targetWidth
        , 300); # do it after 750 ms
    return true
  getControls: (total) ->
    str = '<div class="lw_slider_controls">'
    str += '<div class="lw_slider_count">'
    str += '<span class="lw_slider_count_current">1</span> of '
    str += '<span class="lw_slider_count_total">' + total + '</span>'
    str += '</div>'
    str += '<a href="#" class="lw_slider_prev">&laquo; Previous</a>'
    str += '<a href="#" class="lw_slider_next">Next &raquo;</a>'
    str += '</div>'
    return str
