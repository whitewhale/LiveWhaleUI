$ = livewhale?.jQuery || window.jQuery

$.widget 'lw.lw-timepicker',
  options:
    step: 30
    startTime: new Date(0, 0, 0, 0, 0, 0)
    endTime:   new Date(0, 0, 0, 23, 30, 0)
    separator: ':'
    show24Hours: false
  _create: ->
    $el       = @element
    opts      = @options
    tpOver    = false
    keyDown   = false
    startTime = timeToDate(opts.startTime)
    endTime   = timeToDate(opts.endTime)
    that = this

    # Disable browser autocomplete
    $el.attr('autocomplete', 'OFF')

    times = []
    time = new Date(startTime) # Create a new date object.

    while(time <= endTime)
      times[times.length] = formatTime(time, opts)
      time = new Date(time.setMinutes(time.getMinutes() + opts.step))

    $wrapper = $('<div class="time-picker"/>')

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

    # IX todo - use event delegation
    $("li", $ul).mouseover( ->
      if (!keyDown)
        $("li.selected", $wrapper).removeClass("selected")
        $(this).addClass("selected")
    ).mousedown( ->
       tpOver = true
    ).click( ->
      setTimeVal(elm, this, $wrapper)
      tpOver = false
    )
    
    # Attach to click as well as focus so timePicker can be shown again when
    # clicking on the input when it already has focus.
    $el.focus(@showPicker).click(@showPicker)

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
          if (showPicker()) {
            return false
          }
          $selected = $("li.selected", $ul)
          next = $selected.next().addClass("selected")[0]
          if (next) {
            $selected.removeClass("selected")
            if (next.offsetTop + next.offsetHeight > top + $wrapper[0].offsetHeight) {
              $wrapper[0].scrollTop = top + next.offsetHeight
            }
          }
          else {
            $selected.removeClass("selected")
            next = $("li:first", $ul).addClass("selected")[0]
            $wrapper[0].scrollTop = 0
          }
          return false
          break
        # Enter
        when 13
          if ($wrapper.is(":visible"))
            sel = $("li.selected", $ul)[0]
            setTimeVal(elm, sel, $wrapper, opts)
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
    this.getTime = ->
      return timeStringToDate(elm.value, opts)

    # Helper function to set a time input.
    # Takes a Date object.
    this.setTime = (time) ->
      elm.value = formatTime(normaliseTime(time))
      # Trigger element's change events.
      $(elm).change()

  showPicker: ->
    if ($wrapper.is(":visible")) then return false

    $("li", $wrapper).removeClass("selected")

    # Position:
    # get offset rather than position because picker appended to body 
    elmOffset = $el.offset()

    $wrapper.css
      top:  elmOffset.top + $el.outerHeight()
      left: elmOffset.left

    # Show picker. This has to be done before scrollTop is set since that
    # can't be done on hidden elements.
    $wrapper.show()

    # Try to find a time in the list that matches the entered time.
    if (elm.value.match(/[0-9]+:[0-9]+[apm]+/))
      time_string = elm.value.replace('am',' AM').replace('pm',' PM')
    else
      time_string = elm.value

    time = if (elm.value) then timeStringToDate(time_string, opts) else startTime

    startMin = startTime.getHours() * 60 + startTime.getMinutes()
    min = (time.getHours() * 60 + time.getMinutes()) - startMin
    steps = Math.round(min / opts.step)
    roundTime = normaliseTime(new Date(0, 0, 0, 0, (steps * opts.step + startMin), 0))
    roundTime = if (startTime < roundTime && roundTime <= endTime) then roundTime else startTime
    $matchedTime = $("li:contains(" + formatTime(roundTime, opts) + ")", $wrapper)

    if ($matchedTime.length > 1)
      tmp = false
      theTime = formatTime(roundTime, opts).toUpperCase()

      $.each $matchedTime, (key,val) ->
        if (val.innerHTML==theTime) then tmp = val

      if (tmp) $matchedTime = then $(tmp)

    if ($matchedTime.length)
      $matchedTime.addClass("selected")
      # Scroll to matched time.
      $wrapper[0].scrollTop = $matchedTime[0].offsetTop

    return true
  setTimeVal: (elm, sel, $wrapper, settings) ->
    # Update input field
    elm.value = $(sel).text()

    # Trigger element's change events.
    $(elm).change()

    # Keep focus for all but IE (which doesn't like it)
    if (!$.browser.msie) then elm.focus()

    # Hide picker
    $wrapper.hide()

  formatTime: (time, settings) ->
    h = time.getHours()
    hours = settings.show24Hours ? h : (((h + 11) % 12) + 1)
    minutes = time.getMinutes()

    return formatNumber(hours,false) + settings.separator + formatNumber(minutes,true) + (settings.show24Hours ? '' : ((h < 12) ? ' AM' : ' PM'))
  
  get12HourTime: (dt) ->
    hours = dt.getHours()
    hours = (((h + 11) % 12) + 1)
    am_pm = if (h < 12) then ' AM' else ' PM'

    return @_pad(hours, 2) + @options.separator + @_pad(dt.getMinutes(), 2)

  
  _pad: (n, c) ->
    n = String(n)
    while (n.length < c)
      n = '0' + n
    return n

  formatNumber: (value, is_padded) ->
    return ((is_padded && value < 10) ? '0' : '') + value

  timeToDate: (input, settings) -> 
    return (typeof input === 'object') ? normaliseTime(input) : timeStringToDate(input, settings)

  timeStringToDate: (input, settings) ->
    if (!input) then return null; 

    array = input.split(settings.separator)
    hours = parseFloat(array[0])
    minutes = parseFloat(array[1])

    # Convert AM/PM hour to 24-hour format.
    if (!settings.show24Hours) {
      if (hours === 12 && input.indexOf('AM') !== -1)
        hours = 0
      else if (hours !== 12 && input.indexOf('PM') !== -1)
        hours += 12
    time = new Date(0, 0, 0, hours, minutes, 0)
    return normaliseTime(time)

  # Normalise time object to a common date.
  normaliseTime: (time) ->
    time.setFullYear(2001)
    time.setMonth(0)
    time.setDate(0)
    return time

(function($){
  $.fn.timePicker = function(options) {
    # Build main options before element iteration
    var settings = $.extend({}, $.fn.timePicker.defaults, options)

    return this.each(function() {
      $.timePicker(this, settings)
    })
  }

  $.timePicker = function (elm, settings) {
    var e = $(elm)[0]
    return e.timePicker || (e.timePicker = new $._timePicker(e, settings))
  }

  $._timePicker = function(elm, settings) {
    var tpOver    = false,
        keyDown   = false,
        startTime = timeToDate(settings.startTime, settings),
        endTime   = timeToDate(settings.endTime, settings),
        $el      = $(elm)

    $el.attr('autocomplete', 'OFF') # Disable browser autocomplete

    var times = []
    var time = new Date(startTime) # Create a new date object.
    while(time <= endTime) {
      times[times.length] = formatTime(time, settings)
      time = new Date(time.setMinutes(time.getMinutes() + settings.step))
    }

    var $wrapper = $('<div class="time-picker'+ (settings.show24Hours ? '' : ' time-picker-12hours') +'"></div>')
    var $ul = $('<ul/>')

    # Build the list.
    for(var i = 0 i < times.length; i++) {
      $ul.append("<li>" + times[i] + "</li>")
    }
    $wrapper.append($ul)
    # Append the timPicker to the body and position it.
    $wrapper.appendTo('body').hide()

    # Store the mouse state, used by the blur event. Use mouseover instead of
    # mousedown since Opera fires blur before mousedown.
    $wrapper.mouseover(function() {
      tpOver = true
    }).mouseout(function() {
      tpOver = false
    })

    $("li", $ul).mouseover(function() {
      if (!keyDown) {
        $("li.selected", $wrapper).removeClass("selected")
        $(this).addClass("selected")
      }
    }).mousedown(function() {
       tpOver = true
    }).click(function() {
      setTimeVal(elm, this, $wrapper, settings)
      tpOver = false
    })

    var showPicker = function() {
      if ($wrapper.is(":visible")) {
        return false
      }
      $("li", $wrapper).removeClass("selected")

      # Position:
      # get offset rather than position because picker appended to body 
      var elmOffset = $el.offset()  
      $wrapper.css({'top': elmOffset.top + $el.outerHeight(), 'left': elmOffset.left})

      # Show picker. This has to be done before scrollTop is set since that
      # can't be done on hidden elements.
      $wrapper.show()

      # Try to find a time in the list that matches the entered time.
      var time = elm.value ? timeStringToDate((elm.value.match(/[0-9]+:[0-9]+[apm]+/) ? elm.value.replace('am',' AM').replace('pm',' PM') : elm.value), settings) : startTime
      var startMin = startTime.getHours() * 60 + startTime.getMinutes()
      var min = (time.getHours() * 60 + time.getMinutes()) - startMin
      var steps = Math.round(min / settings.step)
      var roundTime = normaliseTime(new Date(0, 0, 0, 0, (steps * settings.step + startMin), 0))
      roundTime = (startTime < roundTime && roundTime <= endTime) ? roundTime : startTime
      var $matchedTime = $("li:contains(" + formatTime(roundTime, settings) + ")", $wrapper)

		if ($matchedTime.length>1) {
			var tmp=false
			var theTime=formatTime(roundTime, settings).toUpperCase()
			$.each($matchedTime,function(key,val) {
				if (val.innerHTML==theTime) tmp=val
			})
			if (tmp) $matchedTime=$(tmp)
		}
      if ($matchedTime.length) {
        $matchedTime.addClass("selected")
        # Scroll to matched time.
        $wrapper[0].scrollTop = $matchedTime[0].offsetTop
      }
      return true
    }
    # Attach to click as well as focus so timePicker can be shown again when
    # clicking on the input when it already has focus.
    $el.focus(showPicker).click(showPicker)
    # Hide timepicker on blur
    $el.blur(function() {
      if (!tpOver) {
        $wrapper.hide()
      }
    })
    # Keypress doesn't repeat on Safari for non-text keys.
    # Keydown doesn't repeat on Firefox and Opera on Mac.
    # Using kepress for Opera and Firefox and keydown for the rest seems to
    # work with up/down/enter/esc.
    var event = ($.browser.opera || $.browser.mozilla) ? 'keypress' : 'keydown'
    $el[event](function(e) {
      var $selected
      keyDown = true
      var top = $wrapper[0].scrollTop
      switch (e.keyCode) {
        case 38: # Up arrow.
          # Just show picker if it's hidden.
          if (showPicker()) {
            return false
          }
          $selected = $("li.selected", $ul)
          var prev = $selected.prev().addClass("selected")[0]
          if (prev) {
            $selected.removeClass("selected")
            # Scroll item into view.
            if (prev.offsetTop < top) {
              $wrapper[0].scrollTop = top - prev.offsetHeight
            }
          }
          else {
            # Loop to next item.
            $selected.removeClass("selected")
            prev = $("li:last", $ul).addClass("selected")[0]
            $wrapper[0].scrollTop = prev.offsetTop - prev.offsetHeight
          }
          return false
          break
        case 40: # Down arrow, similar in behaviour to up arrow.
          if (showPicker()) {
            return false
          }
          $selected = $("li.selected", $ul)
          var next = $selected.next().addClass("selected")[0]
          if (next) {
            $selected.removeClass("selected")
            if (next.offsetTop + next.offsetHeight > top + $wrapper[0].offsetHeight) {
              $wrapper[0].scrollTop = top + next.offsetHeight
            }
          }
          else {
            $selected.removeClass("selected")
            next = $("li:first", $ul).addClass("selected")[0]
            $wrapper[0].scrollTop = 0
          }
          return false
          break
        case 13: # Enter
          if ($wrapper.is(":visible")) {
            var sel = $("li.selected", $ul)[0]
            setTimeVal(elm, sel, $wrapper, settings)
          }
          return false
          break
        case 27: # Esc
          $wrapper.hide()
          return false
          break
      }
      return true
    })
    $el.keyup(function(e) {
      keyDown = false
    })
    # Helper function to get an inputs current time as Date object.
    # Returns a Date object.
    this.getTime = function() {
      return timeStringToDate(elm.value, settings)
    }
    # Helper function to set a time input.
    # Takes a Date object.
    this.setTime = function(time) {
      elm.value = formatTime(normaliseTime(time), settings)
      # Trigger element's change events.
      $(elm).change()
    }

  } # End fn;

  # Plugin defaults.
  $.fn.timePicker.defaults = {
    step:30,
    startTime: new Date(0, 0, 0, 0, 0, 0),
    endTime: new Date(0, 0, 0, 23, 30, 0),
    separator: ':',
    show24Hours: true
  }

  # Private functions.

  function setTimeVal(elm, sel, $wrapper, settings) {
    # Update input field
    elm.value = $(sel).text()
    # Trigger element's change events.
    $(elm).change()
    # Keep focus for all but IE (which doesn't like it)
    if (!$.browser.msie) {
      elm.focus()
    }
    # Hide picker
    $wrapper.hide()
  }

  function formatTime(time, settings) {
    var h = time.getHours()
    var hours = settings.show24Hours ? h : (((h + 11) % 12) + 1)
    var minutes = time.getMinutes()
    return formatNumber(hours,false) + settings.separator + formatNumber(minutes,true) + (settings.show24Hours ? '' : ((h < 12) ? ' AM' : ' PM'))
  }

  function formatNumber(value,is_padded) {
    return ((is_padded && value < 10) ? '0' : '') + value
  }

  function timeToDate(input, settings) {
    return (typeof input === 'object') ? normaliseTime(input) : timeStringToDate(input, settings)
  }

  function timeStringToDate(input, settings) {
    if (input) {
      var array = input.split(settings.separator)
      var hours = parseFloat(array[0])
      var minutes = parseFloat(array[1])

      # Convert AM/PM hour to 24-hour format.
      if (!settings.show24Hours) {
        if (hours === 12 && input.indexOf('AM') !== -1) {
          hours = 0
        }
        else if (hours !== 12 && input.indexOf('PM') !== -1) {
          hours += 12
        }
      }
      var time = new Date(0, 0, 0, hours, minutes, 0)
      return normaliseTime(time)
    }
    return null
  }

  /* Normalise time object to a common date. */
  function normaliseTime(time) {
    time.setFullYear(2001)
    time.setMonth(0)
    time.setDate(0)
    return time
  }

})(livewhale.jQuery)
