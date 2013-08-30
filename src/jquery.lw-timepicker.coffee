$ = livewhale?.jQuery || window.jQuery

$.widget 'lw.timepicker',
  options:
    step: 30
    startTime: new Date(0, 0, 0, 8, 0, 0)
    endTime:   new Date(0, 0, 0, 23, 30, 0)
    separator: ':'
    show24Hours: false
  _create: ->
    $el       = @element
    opts      = @options
    tpOver    = false
    keyDown   = false
    that = this
    
    @startTime = @stringToDate(opts.startTime)
    @endTime   = @stringToDate(opts.endTime)

    # Disable browser autocomplete
    $el.attr('autocomplete', 'OFF')

    times = []
    time = new Date(@startTime) # Create a new date object.

    while(time <= @endTime)
      times[times.length] = @getFormattedTime(time)
      time = new Date(time.setMinutes(time.getMinutes() + opts.step))

    @$wrapper = $wrapper = $('<div class="time-picker"/>')

    # add time format class
    wrapper_class = if (opts.show24Hours) then '24hours' else '12hours'
    $wrapper.addClass('time-picker-' + wrapper_class)

    $ul = $('<ul/>')

    # Build the list.
    $ul.append("<li>" + time + "</li>") for time in times

    $wrapper.append($ul)

    # Append the timPicker to the body and position it.
    $wrapper.appendTo('body').hide()

    # Store the mouse state, used by the blur event. Use mouseover instead of
    # mousedown since Opera fires blur before mousedown.
    $wrapper.mouseover( ->
      tpOver = true
    ).mouseout( ->
      tpOver = false
    )

    $ul.on 'click', 'li', (e) ->
      $.proxy(that.setTime($(this).text()), that)
      tpOver = false

    # IX todo - use event delegation
    $("li", $ul).mouseover( ->
      if (!keyDown)
        $("li.selected", $wrapper).removeClass("selected")
        $(this).addClass("selected")
    ).mousedown( ->
       tpOver = true
    )
         
    # Attach to click as well as focus so timePicker can be shown again when
    # clicking on the input when it already has focus.
    $el.focus($.proxy(@showPicker, this)).click($.proxy(@showPicker, this))

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
          if (that.showPicker())
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
          if (that.showPicker())
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

  # Helper function to get an inputs current time as Date object.
  # Returns a Date object.
  getTime: ->
    return @stringToDate(@element.val())

  showPicker: ->
    $el  = @element
    opts = @options

    if (@$wrapper.is(":visible")) then return false

    $("li", @$wrapper).removeClass("selected")

    # Position:
    # get offset rather than position because picker appended to body 
    elmOffset = $el.offset()

    @$wrapper.css
      top:  elmOffset.top + $el.outerHeight()
      left: elmOffset.left

    # Show picker. This has to be done before scrollTop is set since that
    # can't be done on hidden elements.
    @$wrapper.show()

    # Try to find a time in the list that matches the entered time.
    if ($el.val().match(/[0-9]+:[0-9]+[apm]+/))
      time_string = $el.val().replace('am',' AM').replace('pm',' PM')
    else
      time_string = $el.val()

    time = if ($el.val()) then @stringToDate(time_string) else @startTime

    startMin = @startTime.getHours() * 60 + @startTime.getMinutes()
    min = (time.getHours() * 60 + time.getMinutes()) - startMin
    steps = Math.round(min / opts.step)
    roundTime = @_normalizeTime(new Date(0, 0, 0, 0, (steps * opts.step + startMin), 0))
    roundTime = if (@startTime < roundTime && roundTime <= @endTime) then roundTime else @startTime
    $matchedTime = $("li:contains(" + @getFormattedTime(roundTime, opts) + ")", @$wrapper)

    if ($matchedTime.length > 1)
      tmp = false
      theTime = @getFormattedTime(roundTime).toUpperCase()

      $.each $matchedTime, (key,val) ->
        if (val.innerHTML is theTime) then tmp = val

      if (tmp) then $matchedTime = $(tmp)

    if ($matchedTime.length)
      $matchedTime.addClass("selected")
      # Scroll to matched time.
      @$wrapper[0].scrollTop = $matchedTime[0].offsetTop

    return true
  setTime: (val) ->
    $el = @element
    
    # if date object
    if (val instanceof Date)
      val = @getFormattedTime(@_normalizeTime(val))

    # Update input field
    $el.val(val)

    # Trigger element's change events.
    $el.change()

    # Keep focus for all but IE (which doesn't like it)
    if (!$.browser.msie) then $el.focus()

    # Hide picker
    @$wrapper.hide()
  getFormattedTime: (dt) ->
    return if (@options.show24Hours) then @get24HourTime(dt) else @get12HourTime(dt)
  get12HourTime: (dt) ->
    hours = dt.getHours()
    hours = ((hours + 11) % 12) + 1
    am_pm = if (hours < 12) then ' AM' else ' PM'
    return @_pad(hours, 2) + @options.separator + @_pad(dt.getMinutes(), 2)
  get24HourTime: (dt) ->
    return @_pad(dt.getHours(), 2) + @options.separator + @_pad(dt.getMinutes(), 2)
  # str format: hours separator minutes 
  stringToDate: (str) ->
    return @_normalizeTime(str) if (str instanceof Date)
    return null if (!str)

    opts = @options

    array   = str.split(opts.separator)
    hours   = parseInt(array[0], 10)
    minutes = parseInt(array[1], 10)

    # Convert AM/PM hour to 24-hour format.
    if (!@options.show24Hours)
      if (hours is 12 and str.indexOf('AM') isnt -1)
        hours = 0
      else if (hours isnt 12 and str.indexOf('PM') isnt -1)
        hours += 12

    dt = new Date(0, 0, 0, hours, minutes, 0)
    return @_normalizeTime(dt)
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
