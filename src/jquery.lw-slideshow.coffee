$ = livewhale?.jQuery || window.jQuery

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
    if (!total) then return false

    @$wrapper  = $el.wrap('<div class="lw_slideshow_wrapper" />').parent()
    @$controls = $controls = $(@getControls(total))
    @$prev     = $controls.find('.lw_slideshow_prev')
    @$next     = $controls.find('.lw_slideshow_next')
    @$current  = $el.children().eq(0)
    @$previous = null
    
    # add class to parent so controls can be hidden
    if (total is 1) then @$wrapper.addClass('lw_slideshow_one_slide')

    # attach controls
    if ('prepend' is opts.controlPlacement)
      @$controls.prependTo(@$wrapper)
    else
      @$controls.appendTo(@$wrapper)

    # add slideshow classes
    $el.addClass('lw_slideshow').children().addClass('lw_slideshow_slide')

    # add custom class if any
    if (opts.customClass) then @$wrapper.addClass(opts.customClass)

    # handler for scroll links 
    @$controls.on 'click', 'a', (evt) ->
      evt.preventDefault()
      $target = $(evt.target)

      # do nothing if the control is disabled
      if ($target.is('.lw_disabled')) then return false

      # if it's the "next" link, otherwise it's a previous link
      if ($target.is('.lw_slideshow_next')) then that.next()
      if ($target.is('.lw_slideshow_prev')) then that.prev()

      return true

    # if first slide contains an image, wait for it to load before showing slide
    # it is possible for slides to contain content other than images
    $first_img = $el.children().eq(0).find('img')
    if ($first_img.length)
      $first_img.one('load', ->
        that.showSlide()
        that.$wrapper.width($first_img.width())
      ).each( ->
        # IX - the height check is for IE10 which doesn't appear to set the complete property
        if (this.complete or $(this).height() > 0) then $(this).load()
      )
    else
      @showSlide()

    return true
  _setOption: (key, value) ->
    return
  # remove handlers and return slideshow markup to original state
  _destroy: (callback) ->
    $el = @element
    if (@$controls) then @$controls.remove() # controls do not exist if slideshow has only one image
    if (@$wrapper) then $el.unwrap()
    $el
      .removeClass('.lw_slideshow')
      .children()
        .removeClass('.lw_slideshow_slide')
    if (@options.customClass) then @$wrapper.removeClass(@options.customClass)
    return true
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
    @$controls.find('.lw_slideshow_count_current').html($slide.index() + 1)

    # stop any animation on the slideshow and its children
    $slide.stop().children('.lw_slideshow_slide').stop().css('z-index', 0)

    $slide.css { zIndex: '100' }

    # fade in the slide
    $slide.fadeTo 100, 1, ->
      if (that.$previous) then that.$previous.css('z-index', 0) #  
      $slide.siblings('.lw_slideshow_slide').css('opacity', 0) # hide siblings 
      # toggle the prev and next control states
      that.$prev.toggleClass('lw_disabled', !$slide.prev('.lw_slideshow_slide').length)
      that.$next.toggleClass('lw_disabled', !$slide.next('.lw_slideshow_slide').length)

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
    str = '<div class="lw_slideshow_controls">'
    str += '<div class="lw_slideshow_count">'
    str += '<span class="lw_slideshow_count_current">1</span> of '
    str += '<span class="lw_slideshow_count_total">' + total + '</span>'
    str += '</div>'
    str += '<a href="#" class="lw_slideshow_prev">&laquo; Previous</a>'
    str += '<a href="#" class="lw_slideshow_next">Next &raquo;</a>'
    str += '</div>'
    return str
