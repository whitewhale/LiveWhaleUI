$ = livewhale?.jQuery || window.jQuery

$.widget 'lw.multisuggest',
  options:
    name:      'name'
    data:      []
    type:      'items'
    create:    false
    selected:  []
    onlyone:   false
    options:
      keywords: null
  _create: ->
    opts = @options
    $el  = @element
    that = this

    # add title to keywords and normalize
    $.each opts.data, ->
      @keywords = if (@keywords) then ' ' + that._normalizeKeywords(@keywords) else ""
      @keywords = that._normalizeKeywords(@title) + @keywords

    @$suggestions = $('<ul class="lw-multisuggest-suggestions"/>')
    @$input = $('<input type="text" class="lw-multisuggest-input"/>')

    $el
      .addClass("lw-multisuggest lw-multisuggest-#{ opts.type } lw_false_input")
      .append(@$suggestions)
      .append(@$input)

    # hide and remove lw_false_input class if places widget on event_edit page 
    if (opts.type is 'places' && livewhale.page is 'events_edit')
      $el.addClass('lw_hidden').removeClass('lw_false_input')
  open: ->
    if !@$overlay
      @initOverlay()
    
    # build selected array 
    selected = []
    @element.find('.lw_multisuggest_item:not(.lw_multisuggest_new)').each ->
      $this = $(this)
      selected.push
        id: $this.find('input').val()
        title: $.trim($this.text())
        is_locked: $this.is('.lw_locked')

    # open the overlay
    @_overlay.overlay('open')
  initOverlay: ->
    $el = @element
    opts = @options
    that = this
    $input = @input
    $suggestions = @suggestions

    overlay = '''
      <div class="lw-multisuggest-overlay">
        <h3>All #{ opts.type }</h3>
        <div class="lw-items"></div>
        <button type="button" class="lw-save"/>Use selected #{ opts.type }</button>
        <span class="lw-cancel">or <a href="#">cancel and close</a></span>
      </div>
      '''

    @$overlay = $overlay = $(overlay)
      .overlay(
        closeSelector: '.lw_cancel a'
        autoOpen: false
      )
      # save items selected in overlay
      .on('click', '.lw-save', ->
        $el.find('.lw_multisuggest_item:not(.lw_multisuggest_new)').remove()

        $overaly.find('.lw-selected').each ->
          $this = $(this)
          that.add
            title:      $.trim($this.text())
            id:         $this.siblings('input').val()
            is_locked:  $this.is('.lw_locked')

        if (!opts.onlyone or !selected.length)
          @$input.css('visibility', 'visible').focus().keyup()

        $overlay.overlay('close')
        return false
      )

    $overlay.find('.lw-items').multiselect
      type:      opts.type
      data:      opts.data
      selected:  selected
      onlyone:   opts.onlyone


    # add message to separate with commas if not places
    #if (opts.type is 'tags')
    #  $('<p/>').addClass('lw_multisuggest_help').text('Separate ' + opts.type + ' with commas').insertAfter($show_link)

    $el.click( ->
      $el.find('.lw-item.lw-selected').removeClass('lw-selected')

      # only one is wanted, don't allow clicking in
      return false if (opts.onlyone and $el.find('.lw-item').length >= 1)
      $input.css('visibility', 'visible').focus().keyup()
    )
    .on('click', '.lw-item', ->
      $(this).addClass('lw-selected').siblings().removeClass('lw-selected')

      $input
        .val('')
        .css('visibility', 'visible') # it needs to be visible to focus
        .focus()
        .css('visibility', 'hidden')

      # cancel bubbling
      return false
    )
    .on('click', '.lw-remove', (e) ->
      e.preventDefault()

      $item = $(this).closest('.lw-item')

      return false if $item.is('.lw-locked')

      # remove item if not locked
      $item.remove()
      $input.css('visibility', 'visible').show(0)

      # trigger the change event on the suggestor
      @_trigger('change')

      # trigger the change event on the suggestor
      @_trigger('remove_multisuggest')

      return false
    )
    .on('click', '.lw-suggestions li', (e) ->
      $li = $(this)
      id = $li.find('input').val()
      existing = $el.find('.lw-item input[value=' + id + ']').parent()

      # we're clearing the input val regardless of what happens
      $input.val('')

      # mark item selected if it exists, otherwise add it as a new item 
      if (existing.length)
        existing.addClass('lw-selected')
        $input.focus().css('visibility', 'hidden')
      else
        that.add
          title: $.trim($li.text())
          id: id
        if (opts.onlyone) then $input.hide(0) else $input.focus()

      # cancel bubbling
      return false
    )

    # .blur() doesn't QUITE work here that's why we have to have an annoying 200ms timeout
    $input.blur( ->
      $el.find('.lw-item.lw-selected').removeClass('lw-selected')
      lastquery = ''
      hidesuggestions = setTimeout( ->
        # hide the suggestion popup (we can't hide it earlier, in case the user has clicked it)
        $suggestions.hide()

        # we do the following inside the timer in case clicking on a suggestion has already selected a result
        if ($input.val())
          # trigger a fake return key keydown event
          e = $.Event('keydown')
          e.which = 13
          $input.trigger(e)
      , 200)
    )
    # on each keypress, filter the results
    .keyup((e) ->
      # grab query, sanitize it // TODO COMPILE THESE REGEXPS
      query = $.trim($(this).val().toLowerCase().replace(/[,\-\/\s]+/g, ' ').replace(/[^a-zA-Z 0-9\.]+/g, ''))
      
      # do nothing if the query is unchanged
      return false if (query is lastquery)

      # empty and hide the suggestions list
      $suggestions.empty().hide()

      # if this query is NOT a subset of the last query, reinitialize the matches and search on all terms
      if (query.indexOf(lastquery) isnt 0 || !lastquery.length)
        matches = opts.data
        subquery = query
      else
        # otherwise, since this query IS a subset of the last query, no need to search the last query's terms
        subquery = query.substring(query.lastIndexOf(' ') + 1, query.length) 

      lastquery = query # store the last query

      # cancel here if the query is zero length
      return false if (!query.length) 

      # filter the result for each word in the query
      $.each(subquery.split(' '), -> 
        search = this
        results = $.grep(matches, (item) ->
          return (' ' + item.keywords).indexOf(' ' + search) >= 0
        )
      )

      if (results.length)
        # regex for highlighting the query terms
        query_exp = new RegExp('(\\b' + query.replace(/\s/g, '|\\b') + ')', 'ig')

        # list the match, with highlighting
        $.each(results, (index, item) ->
          $li = $('<li/>')
          if query is item.keywords then $li.addClass('lw_selected')
          title = (' ' + item.title).replace(query_exp, '<span class="lw_multisuggest_highlight">$1</span>')

          $suggestions.append($li.html('<input type="hidden" value="' + item.id + '"/>' + title))
        )
        position = $input.position()
        $suggestions.css(
          left: position.left + 'px'
          top: position.top + 'px'
        ).show()

        # force select the first item if creation is disabled
        if (!opts.create)
          $suggestions.children.eq(0).addClass('lw_selected')
    )

    # capture special keys on keydown
    .keydown( (e) ->
      selected_item = that.find('.lw_multisuggest_item.lw_selected')

      # First, handle the case of a selected item
      if (selected_item.length)
        switch (e.which)
          when 13 or 32
            # enter/return or space
            e.preventDefault()
            item = selected_item.find('.lw_item_name').text()
            selected_item.find('.lw_multisuggest_remove').trigger('click') # remove the item
            $input.val(item).keyup() # and enter the item for editing
            break
          when 37
            # left arrow
            e.preventDefault()
            prev = selected_item.removeClass('lw_selected').prev()

            # select previous item and return if it exists
            if (prev.length)
              prev.addClass('lw_selected')
              return

            break
          when 39 or 9
            # right arrow or tab
            e.preventDefault()
            next = selected_item.removeClass('lw_selected').next()

            # select next item and return if it exists
            if (next.is('.lw_multisuggest_item'))
              next.addClass('lw_selected')
              return
            break
          when 8
            # del/backspace
            e.preventDefault()
            selected_item.find('.lw_multisuggest_remove').trigger('click')
            break
          else
            # deselect any selected items
            that.find('.lw_multisuggest_item.lw_selected').removeClass('lw_selected') 
            break

        # and show the input
        $input.css('visibility', 'visible')
        return

      # remove previous suggestions that were not selected this time
      suggestall = ->
        $suggestions.empty()
        if (opts.data.length)
          $.each opts.data, (index, item) ->
            $suggestions.append('<li><input type="hidden" value="' + item.id + '"/>' + item.title + '</li>')

          position = $input.position()
          $suggestions.css(
            left: position.left + 'px'
            top: position.top + 'px'
          ).show()

      $selected = $suggestions.find('.lw_selected')

      # Otherwise, handle the autocomplete
      switch (e.which)
        # up arrow
        when 38
          e.preventDefault()

          # if there are no matches, show all matches
          if ($suggestions.is(':hidden')) then suggestall()

          match = $selected.find("span").text().toLowerCase()
          input_val = $.trim($input.val().toLowerCase())

          # if there's only one result and it's a match, don't let users deselect it
          if ($selected.siblings().length is 0 && input_val is match)
            break

          $selected.removeClass('lw_selected')

          if ($selected.prev().length)
            $selected = $selected.prev().addClass('lw_selected')
            position = $selected.position().top

            if (position < 0)
              $suggestions.scrollTop($suggestions.scrollTop() + position)
          else if (!$selected.length)
            $selected = $suggestions.show().find('li:last-child').addClass('lw_selected')
            position = ($selected.position().top + $selected.outerHeight()) - ($suggestions.height() - $suggestions.scrollTop())
            if (position > 0)
              $suggestions.scrollTop(position)
          break
        when 40
          # down arrow
          e.preventDefault()

          if ($suggestions.is(':hidden')) then suggestall() # if there are no matches, show all matches
          
          match = $selected.find("span").text().toLowerCase()
          input_val = $.trim($input.val().toLowerCase())

          # if there's only one result and it's a match, don't let users deselect it
          if ($selected.siblings().length is 0 && match is input_val)
            break

          $selected.removeClass('lw_selected')

          if ($selected.next().length)
            $selected = $selected.next().addClass('lw_selected')
            position = ($selected.position().top + $selected.outerHeight()) - ($suggestions.height() - $suggestions.scrollTop())
            if (position > 0)
              $suggestions.scrollTop(position)
          else
            $suggestions.scrollTop(0)
            if (!$selected.length)
              $selected = $suggestions.children().eq(0).addClass('lw_selected')
          break
        when 13 or 44 or 188 or 9
          # enter/return or comma or comma sometimes return by jQuery or tab
          if (e.which is 13) then e.preventDefault() # always prevent enter

          # disable adding item with comma if we're not editing tags
          if (opts.type isnt 'tags' && (e.which is 44 || e.which is 188))
            break

          existing = []
          if ($selected.length)
            e.preventDefault()

            id = $selected.find('input').val() # selected item id

            existing = that.find('.lw_multisuggest_item input[value=' + id + ']').parent()
            if (!existing.length)
              that.multisuggest 'add',
                title: $.trim($selected.text())
                id: id
          else
            # if there are no matches but creation is disabled
            if (!opts.create)
              return true

            value = $.trim($input.val())

            if (value.length)
              lcvalue = value.toLowerCase()
              existing = that.find('.lw_multisuggest_item .lw_multisuggest_item_name').filter(->
                # match if the string matches the value
                return $.trim($(this).text().toLowerCase()) is lcvalue 
              ).parent()

              if (!existing.length)
                e.preventDefault()
                that.multisuggest('new', value)

          $input.val('').keyup()
          $suggestions.hide()

          if (existing.length)
            existing.addClass('lw_selected')
            $input.css('visibility', 'hidden')

          break
        when 37 or 8
          # left arrow or del/backspace
          # if there's no input, but there are older suggestions
          if (!$.trim($input.val()).length && $input.siblings('.lw_multisuggest_item').length)
            e.preventDefault() # cancel the keypress
            $input
              .val('') # remove any spaces just in case
              .css('visibility', 'hidden') # hide the input
              .prev().addClass('lw_selected') # and select the last item
            $suggestions.empty().hide() # hide suggestions
          break
    )

    # when scrolling the suggestions
    $suggestions.scroll ->
      clearTimeout(hidesuggestions) # don’t hide the suggestions list
      $input.focus() # and keep the focus in the input

    # if we need to preselect
    if (opts.selected.length)
      # with each preselected tag
      $.each opts.selected, ->
        if (this.id)
          that.multisuggest('add', this) # select it;
        else # otherwise
          that.multisuggest('new', this.title) # add it as a new tag

      # don't show input if onlyone is on and we have one
      if (opts.onlyone && opts.selected.length > 0)
        $input.css('visibility', 'hidden').blur()

  # value is an object with keys id and title
  add: (value) ->
    html  = '<input type="hidden" name="' + opts.name + '[]" value="" />'
    html += '<span class="lw_item_name">' + value.title + '</span><span class="lw_multisuggest_remove">×</span>'

    $item  = $('<div class="lw_multisuggest_item"/>').html(html)

    # if locked, add class and remove name attribute from input 
    if (value.is_locked) then $item.addClass('lw_locked').find('input').removeAttr('name')

    # add the hidden iput item before the multi
    @input.before($item)

    that.trigger('change.multisuggest') # trigger the change event on the suggestor
  # value is the new item's title 
  new: (name) ->
    name = $.trim(name)
    html = '''
      <div class="lw-item lw-new">
        <input type="hidden" name="#{ opts.name }_added[]" value="#{ name }" />
        <span class="lw-name">#{ name }</span>
        <span class="lw-remove">×</span>
      </div>
      '''
    @input.before(html)
    @_trigger('change.multisuggest') # trigger the change event on the suggestor
  _normalizeKeywords: (string) ->
    return string
      .toLowerCase()
      .replace('&amp', 'and')
      .replace(/[,\-_\s&\/\\]+/g, ' ') # convert to spaces
      .replace(/[^a-zA-Z 0-9]+/g, '')  # remove non-alphanumeric chars
