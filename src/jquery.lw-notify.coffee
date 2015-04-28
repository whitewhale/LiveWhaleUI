$ = livewhale?.jQuery || window.jQuery

$.widget 'lw.notify',
  options:
    id:           false        # new notices clobber any notices with same id
    message:      'Your Message Here :                                                                 )'
    details:      false        # message details
    customClass:  null         # one or more comma-separated custom classes
    type:         false        # the type of notification (success, failure, warning)
    slideIn:      150          # the time to run the slide animation
    duration:     false        # hide the notification after duration MS
    closeButton:  true         # show a close button?
    callback:     $.noop       # callback once the notice is attached, with the notice as the context
    log:          true         # output a log of the combined notices?
  _create: ->
    opts = @options

    $notice = $('<div class="lw_notice"/>')
    $container = $('<div class="lw_container"/>').appendTo($notice)

    if (opts.type) then $notice.addClass('lw_msg_' + opts.type)
    if (opts.id) then $notice.attr('id', opts.id)

    html  = opts.message
    html += '<a class="lw_notice_close_button" href="#">&times;</a>'

    if (opts.details)
      html += '<div class="lw_notice_details">' + opts.details + '</div>'
      html += '<a href="#" class="lw_notice_showdetails">More...</a>'

    $container.html(html)
    
    # when clicking the close button
    close = $notice.on '.click', '.lw_notice_close_button', ->
      # slide up the notice and remove it
      notice.slideUp 150, ->
        notice.remove()
      return false

    # when clicking to show details
    showdetails = notice.on 'click', '.lw_notice_showdetails', ->
      # create a log
      details = $('<div class="lw_notices_details" id="lw_notices_details_' + opts.id + '"/>')

      # remove any existing overlay log
      $('.lw_notices_details').overlay('remove')

      # if this notice is logged under an ID
      if (opts.id && opts.log)
        notices = self.data('lw_notice_' + opts.id) # get existing notices from this group

        # add each notice to log
        $.each notices, ->
          thiopts.clone(true).appendTo(details); # add it to the log
      else
        notice.clone(true).removeAttr('id').appendTo(details)
      detailopts.overlay() # and show the log as an overlay
      return false

    # if the message should be hidden automatically
    if (opts.duration)
      notice.mouseover ->
        clearTimeout(timeout) # clear the timeout
      .mouseleave ->
        timeout = setTimeout ->
          close.click()
        , opts.duration # set the notice to hide
      .mouseleave() # and set it to hide now

    last = self.find('#' + opts.id) # find any existing notice
    opts.callback.apply notice, [last.length] # apply the callback with the notice as context

    if (opts.id) # if we're combining errors
      if (opts.log)
        clone = notice.clone(true).removeAttr('id')
          # clone this notice, with any events intact
        notices = self.data('lw_notice_' + opts.id) or [] # get existing notices from this group
        notices.push(clone); # add the clone to the group
        self.data('lw_notice_' + opts.id, notices) # and store it
        if (notices.length > 1) # if there are other notices like this
          showdetailopts.html((notices.length - 1) + ' more like thiopts...').show() # add the link to view more info and make sure it's showing
          details = $('#lw_notices_details_' + opts.id)

          if (detailopts.length) # and if the user is already viewing the log
            clone.clone(true).appendTo(details) # add the current notice to it
      if (last.length) # if there's an existing notice in this group
        last.replaceWith(notice.show()) # replace the existing one with the new one	
        return self # and return now instead of sliding down

    $container = self.find('>.lw_notices')

    if (!$container.length)
      $container = $('<div class="lw_notices lw_element"/>').appendTo(self) # create the container if it doesn't exist

    # add any custom classes defined in options 
    if (opts.custom_class)
      $container.addClass(opts.custom_class)

    notice.hide().appendTo($container).slideDown(opts.slideIn) # and finally show the notice	
    return self
