$ = livewhale?.jQuery || window.jQuery

$.widget 'lw.slideshow',
  options:
    fluidHeight: true
    controlPlacement: 'append'
    customClass: null
    transitionSpeed: 100
    continuousScroll: false
  _create: ->
    $el    = @element
    opts   = @options
    total  = $el.children().length
    that   = this
    height = 0
    width  = 0

    # don't do anything if 1 or no slides 
    if (!total) then return false

    @max_width = $el.parent().width()
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
    $first = $el.children().eq(0).find('img')
    if ($first.length)
      $first.one('load', ->
        that.showSlide()
        return true
      ).each( ->
        if (this.complete) then $(this).load()
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
    $next = @$current.next()
    @$current = if ($next.length) then $next else @element.children(':first-child')
    @showSlide()
  prev: ->
    @$previous = @$current
    $prev = @$current.prev()
    @$current = if ($prev.length) then $prev else @element.children(':last-child')
    @showSlide()
  showSlide: (width, height) ->
    that         = this
    $el          = @element
    opts         = @options
    $slide       = @$current
    $img         = $slide.find('img')
    height       = $el.height()          # current height
    width        = $el.width()           # current width
    targetHeight = $slide.outerHeight(true)       # the height of the slide
    targetWidth  = $slide.outerWidth(true)        # the width of the slide

    # adjust to parent if it is narrower that the image 
    if (targetWidth > @max_width)
      targetWidth = @max_width
      $slide.width(targetWidth)
      # update height now that we've adjusted the image width
      targetHeight = $slide.outerHeight(true)

    # shrink image to fit with border and margin - fixes FF bug
    img_border = $img.outerWidth(true) - $img.width()
    if (img_border) then $img.width(targetWidth - img_border)

    # return right away if no slide set in data
    if (!$slide || !$slide.length) then return false

    $slide.siblings().removeClass('lw_slideshow_active')
    $slide.addClass('lw_slideshow_active')

    @$prev.addClass('lw_disabled')
    @$next.addClass('lw_disabled')

    # update count in controlls
    @$controls.find('.lw_slideshow_count_current').html($slide.index() + 1)

    # stop any animation on the slideshow and its children
    $slide.stop().siblings('.lw_slideshow_slide').stop().css('z-index', 0)

    $slide.css { zIndex: '5' }

    # fade in the slide
    $slide.fadeTo opts.transitionSpeed, 1, ->
      if (that.$previous) then that.$previous.css('z-index', 0) #  
      $slide.siblings('.lw_slideshow_slide').css('opacity', 0) # hide siblings 

      # toggle the prev and next control states
      if (!opts.continuousScroll)
        that.$prev.toggleClass('lw_disabled', !$slide.prev('.lw_slideshow_slide').length)
        that.$next.toggleClass('lw_disabled', !$slide.next('.lw_slideshow_slide').length)
      else
        that.$prev.removeClass('lw_disabled')
        that.$next.removeClass('lw_disabled')

    # adjust wrapper width if different
    if (@$wrapper.width() isnt $slide.width()) then @$wrapper.width(targetWidth)

    # animate size change if fluidHeight
    if (@options.fluidHeight)
      # shrink the slideshow
      if (height isnt targetHeight or width isnt targetWidth)
        $el.animate(
          'height': targetHeight
          'width': targetWidth
        , 300)
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
