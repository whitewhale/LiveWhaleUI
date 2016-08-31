$ = livewhale?.jQuery || window.jQuery

$.widget 'lw.timepicker',
  options:
    step: 30
    startTime: new Date(0, 0, 0, 6, 0, 0)
    endTime:   new Date(0, 0, 0, 23, 30, 0)
    separator: ':'
    show24Hours: false
  _create: ->
    $el       = @element
    opts      = @options
    tpOver    = false
    keyDown   = false
    that      = this
    
    @startTime = @stringToDate(opts.startTime)
    @endTime   = @stringToDate(opts.endTime)
    @time      = @stringToDate($el.val())

    # Disable browser autocomplete
    $el.attr('autocomplete', 'OFF')

    @$wrapper = $wrapper = $('<div class="lw-timepicker"/>')
    @$ul = $ul = $('<ul/>')

    # Append list to wrapper, and append wrapper to body 
    $wrapper.append($ul).appendTo('body').hide()

    # add format class
    wrapper_class = if (opts.show24Hours) then '24hours' else '12hours'
    $wrapper.addClass('lw-timepicker-' + wrapper_class)

    # Store the mouse state, used by the blur event. Use mouseover instead of
    # mousedown since Opera fires blur before mousedown.
    $wrapper.mouseover( ->
      tpOver = true
    ).mouseout( ->
      tpOver = false
    )

    $ul.on 'click', 'li', (e) ->
      that.setTime($(this).text())
      tpOver = false
      return true

    # IX todo - use event delegation
    $("li", $ul).mouseover( ->
      if (!keyDown)
        $("li.selected", $wrapper).removeClass("selected")
        $(this).addClass("selected")
      return true
    ).mousedown( ->
       tpOver = true
       return true
    )

    # Attach to click as well as focus so timePicker can be shown again when
    # clicking on the input when it already has focus.
    $el.focus($.proxy(@open, this)).click($.proxy(@open, this))

    # Hide timepicker on blur
    $el.blur ->
      if (!tpOver) then $wrapper.hide()

    # Keypress doesn't repeat on Safari for non-text keys.
    # Keydown doesn't repeat on Firefox and Opera on Mac.
    # Using kepress for Opera and Firefox and keydown for the rest seems to
    # work with up/down/enter/esc.
    event = if ($.browser.opera || $.browser.mozilla) then 'keypress' else 'keydown'

    $el[event] (e) ->
      $selected
      keyDown = true
      top = $wrapper[0].scrollTop

      switch (e.keyCode)
        # Up arrow.
        when 38
          # Just show picker if it's hidden.
          if (that.open())
            return false

          $selected = $("li.selected", $ul)
          prev = $selected.prev().addClass("selected")[0]

          if (prev)
            $selected.removeClass("selected")
            # Scroll item into view.
            if (prev.offsetTop < top)
              $wrapper[0].scrollTop = top - prev.offsetHeight
          else
            # Loop to next item.
            $selected.removeClass("selected")
            prev = $("li:last", $ul).addClass("selected")[0]
            $wrapper[0].scrollTop = prev.offsetTop - prev.offsetHeight
          return false
          break
        # Down arrow, similar in behaviour to up arrow.
        when 40
          if (that.open())
            return false
          $selected = $("li.selected", $ul)
          next = $selected.next().addClass("selected")[0]
          if (next)
            $selected.removeClass("selected")
            if (next.offsetTop + next.offsetHeight > top + $wrapper[0].offsetHeight)
              $wrapper[0].scrollTop = top + next.offsetHeight
          else
            $selected.removeClass("selected")
            next = $("li:first", $ul).addClass("selected")[0]
            $wrapper[0].scrollTop = 0
          return false
          break
        # Enter
        when 13
          if ($wrapper.is(":visible"))
            $sel = $("li.selected", $ul)[0]
            that.setTime($sel.val())
          return false
          break
        # Esc
        when 27
          $wrapper.hide()
          return false
          break

      return true

    $el.keyup (e) ->
      keyDown = false

  open: ->
    $el  = @element
    opts = @options

    # do nothing if timepicker already visible
    if (@$wrapper.is(":visible")) then return false

    @_buildTimeList()
    @_position()

    # we have to show before scrollTop, which requires visiblity
    @$wrapper.show()

    # Try to find a time in the list that matches the entered time.
    time = @time or @startTime

    startMin     = @startTime.getHours() * 60 + @startTime.getMinutes()
    min          = (time.getHours() * 60 + time.getMinutes()) - startMin
    steps        = Math.round(min / opts.step)
    roundTime    = @_normalizeTime(new Date(0, 0, 0, 0, (steps * opts.step + startMin), 0))
    roundTime    = if (@startTime < roundTime && roundTime <= @endTime) then roundTime else @startTime
    $matchedTime = $("li:contains(" + @getFormattedTime(roundTime) + ")", @$ul)

    # add selected class, and scroll to matched time
    if ($matchedTime.length)
      $matchedTime.addClass("selected")
      @$wrapper[0].scrollTop = $matchedTime[0].offsetTop

    return true
  setTime: (val) ->
    $el = @element

    if (!val) then return false
    
    # if date object
    if (val instanceof Date)
      @time = @_normalizeTime(val)
      val = @getFormattedTime(@_normalizeTime(val))
    else
      @time = @stringToDate(val)

    # Update input field
    $el.val(val)

    # Trigger element's change events.
    $el.change()

    # Keep focus for all but IE (which doesn't like it)
    if (!$.browser.msie) then $el.focus()

    # Hide picker
    @$wrapper.hide()
  getFormattedTime: (dt, show24Hours) ->
    if (show24Hours is undefined) then show24Hours = @options.show24Hours
    return if (@options.show24Hours) then @get24HourTime(dt) else @get12HourTime(dt)
  get12HourTime: (dt) ->
    hours = dt.getHours()
    am_pm = if (hours < 12) then ' AM' else ' PM'
    hours = ((hours + 11) % 12) + 1
    return hours + @options.separator + @_pad(dt.getMinutes(), 2) + am_pm
  get24HourTime: (dt) ->
    return @_pad(dt.getHours(), 2) + @options.separator + @_pad(dt.getMinutes(), 2)
  # str format: hours separator minutes 
  stringToDate: (str) ->
    # return normalized date if str a Date object
    return @_normalizeTime(str) if (str instanceof Date)

    opts    = @options
    array   = str.split(opts.separator)
    
    if (array.length isnt 2) then return false

    hours   = parseInt(array[0], 10)
    minutes = parseInt(array[1], 10)

    # convert am/pm 24 hour equivalent
    if (!@options.show24Hours)
      str = str.toLowerCase()
      if (hours is 12 and str.indexOf('am') isnt -1)
        hours = 0
      else if (hours isnt 12 and str.indexOf('pm') isnt -1)
        hours += 12

    return @_normalizeTime( new Date(0, 0, 0, hours, minutes, 0) )
  _setOption: (key, value) ->
    opts = @options

    # update selected if changing format
    if ('show24Hours' is key and value isnt opts.show24Hours and @time)
      @element.val(@getFormattedTime(@time, value || false))

    @_super(key, value)
  _buildTimeList: ->
    times = []
    time = new Date(@startTime) # Create a new date object.
    step = @options.step

    @$ul.empty()

    while(time <= @endTime)
      @$ul.append("<li>" + @getFormattedTime(time) + "</li>")
      time = new Date(time.setMinutes(time.getMinutes() + step))
  _position: ->
    $el = @element
    # get offset rather than position because picker appended to body 
    el_offset = $el.offset()

    @$wrapper.css
      top:  el_offset.top + $el.outerHeight() + 1
      left: el_offset.left
  # pad with zeros until c chars long 
  _pad: (n, c) ->
    n = String(n)
    while (n.length < c)
      n = '0' + n
    return n
  # Normalise time object to a common date.
  _normalizeTime: (time) ->
    time.setFullYear(2001)
    time.setMonth(0)
    time.setDate(0)
    return time
