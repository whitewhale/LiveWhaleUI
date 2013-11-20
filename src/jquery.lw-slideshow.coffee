$.widget 'lw.slideshow',
  # default options
  options:
    fluidHeight: true
    controlPlacement: 'append'
    customClass: null

  # init widget
  _create: ->
    $el = @element
    opts = @options
    total = $el.children().length
    that = this
    height = 0
    width = 0

    @$wrapper = $el.wrap('<div class="lw_slider_wrapper" />').parent()
    @$controls = $(@getControls(total))
    @$current = $el.children().eq(0)
    @$previous = null

    # attach controls
    if ('prepend' is opts.controlPlacement)
      @$controls.prependTo(@$wrapper)
    else
      @$controls.appendTo(@$wrapper)

    # TODO - don't init slideshow if only one image - quick hack for calendar demo
    if (1 is total)
      @$controls.hide()

    $el.addClass('lw_slider')
    #.height($el.children().eq(0).height())
    #.width($el.width()) 
    .children().addClass('lw_slider_slide').css(
      opacity: 0
      position: 'absolute'
      top: '50%'
      left: '50%'
    )

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

    # get height of tallest image, and width of widest image 
    if (!@options.fluidHeight)
      $el.find('img').each ->
        $this = $(this)
        if ($this.height() > height) then height = $this.height()
        if ($this.width() > width) then width = $this.width()

      $el.height(height)
      $el.width(width)

    $first_img = $el.children().eq(0).find('img')

    # if the first item has an image, wait for image to load before showing slide
    if ($first_img.length)
      $('<img/>').load((evt) ->
        that.showSlide()
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
    $el = @element
    $slide = @$current
    that = this
    height = $el.height()
    # current height
    targetHeight = $slide.height()
    # the height of the slide
    width = $el.width()
    # current width
    targetWidth = $slide.width() # the width of the slide
    # return right away if no slide set in data
    if (!$slide || !$slide.length) then return false

    @$controls.find('.lw_slideshow_prev').addClass('lw_disabled')
    @$controls.find('.lw_slideshow_next').addClass('lw_disabled')

    # update count in controlls
    @$controls.find('.lw_slider_count_current').html($slide.index() + 1)

    $slide.stop() # stop any animation on the slideshow
    .children('.lw_slider_slide').stop().css('z-index', 0); # and its children straightaway
    $slide.css
      marginTop: -(targetHeight + parseInt($el.css('padding-top'), 10) + parseInt($el.css('padding-bottom'), 10)) / 2
      marginLeft: -targetWidth / 2
      zIndex: '100'

    # fade in the slide
    $slide.fadeTo 100, 1, -> 
      if (that.$previous) then that.$previous.css('z-index', 0)
      # hide siblings 
      $slide.siblings('.lw_slider_slide').css('opacity', 0)
      # toggle the previous control state
      that.$controls.find('.lw_slider_prev').toggleClass('lw_disabled', !$slide.prev('.lw_slider_slide').length)
      # toggle the next control state
      that.$controls.find('.lw_slider_next').toggleClass('lw_disabled', !$slide.next('.lw_slider_slide').length)

    if (@options.fluidHeight)
      # if we need to shrink the slideshow
      if (height > targetHeight or width > targetWidth)
        $el.animate(
          'height': targetHeight
          'width': targetWidth
        , 300)
      # if we need to grow the slideshow
      if (height < targetHeight or width < targetWidth)
        $el.animate(
          'height': targetHeight
          'width': targetWidth
        , 300); # do it after 750 ms
  getControls: (total) ->
    return '<div class="lw_slider_controls' + (total > 1 ? '' : ' lw_slider_single') + '">' + '<div class="lw_slider_count">' + '<span class="lw_slider_count_current">1</span> of ' + '<span class="lw_slider_count_total">' + total + '</span>' + '</div>' + '<a href="#" class="lw_slider_prev">&laquo; Previous</a>' + '<a href="#" class="lw_slider_next">Next &raquo;</a>' + '</div>'

