$ = livewhale?.jQuery || window.jQuery

$.widget 'lw.lw-multisuggest',
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

    toSpace  = /[,\-_\s&\/\\]+/g   # regexp for elements that should become spaces
    toRemove = /[^a-zA-Z 0-9]+/g  # regexp for elements that should be removed

    # what the fuck!
    $.each opts.data, ->
      title = this.title.toLowerCase().toLowerCase().replace('&amp', 'and').replace(toSpace, ' ').replace(toRemove, '')
      if (this.keywords) 
        keywords = ' ' + this.keywords.toLowerCase().toLowerCase().replace('&amp;', 'and').replace(toSpace, ' ').replace(toRemove, '')

      this.keywords =  + (this.keywords ?  : ''); # keyword for matching against

    $suggest = $('<div class="lw_multisuggest lw_multisuggest_' + opts.type + '"/>')
      .html('<ul class="lw_multisuggest_suggestions"/></div>')
      .appendTo(self)

    if (!(opts.type === 'places' && livewhale.page === 'events_edit'))
      $suggest.addClass('lw_false_input')
    else
      $suggest.addClass('lw_hidden')

    matches = opts.data
    lastquery = ''
    $suggestions = suggest.find('.lw_multisuggest_suggestions')
    hidesuggestions

    input = $('<input type="text" class="lw_multisuggest_input"/>').appendTo($suggest)

    if (opts.data.length)
      # check syntax for CS ternary alternative
      show_text = if (opts.type === 'places') then 'or ' else ''
      show_text += 'Show all ' + opts.type

      $show_link = $('<a class="lw_multisuggest_showall" href="#"/>')
        .text(show_text)
        .insertAfter(opts.type !== 'places' ? suggest : $('#places_add_new'))
        .click ->
          all = $('<div id="lw_multisuggest_all"><h3>All ' + opts.type + '</h3><input type="button" value="Use selected ' + opts.type + '" id="lw_multisuggest_all_save"/><span class="lw_cancel">or <a href="#">cancel and close</a></span></div>')
          items = $('<div id="lw_multisuggest_all_items"/>').insertAfter(all.find('h3'))
          selected = []

          self.find('.lw_multisuggest_item:not(.lw_multisuggest_new) input').each ->
            selected.push
              id: $(this).val()
              title: $.trim($(this).parent().text())
              is_locked: $(this).parent().is('.lw_locked')

        items.multiselect
          type: opts.type
          data: opts.data
          selected: selected
          onlyone: opts.onlyone

        all.overlay
          close: '.lw_cancel a'

        $('#lw_multisuggest_all_save').click ->
          self.find('.lw_multisuggest_item:not(.lw_multisuggest_new)').remove()

          all.find('.lw_selected').each ->
            self.multisuggest 'add',
              title: $.trim($(this).text())
              id: $(this).siblings('input').val()
              is_locked: $(this).is('.lw_locked')

          if (!opts.onlyone or selected.length < 1)
            input.css('visibility', 'visible').focus().keyup()

          all.overlay('remove')
        return false

      # add message to separate with commas if not places
      if (opts.type === 'tags')
        $('<p/>').addClass('lw_multisuggest_help').text('Separate ' + opts.type + ' with commas').insertAfter($show_link)

    self.on('click', '.lw_multisuggest', ->
      # deselect any selected items
      $(this).find('.lw_multisuggest_item.lw_selected').removeClass('lw_selected') 
      if (opts.onlyone && $('.lw_multisuggest_item').length >= 1)
        return false # only one is wanted, don't allow clicking in

      input.css('visibility', 'visible').focus().keyup()
    ).on('click', '.lw_multisuggest_item', ->
      $(this).addClass('lw_selected').siblings().removeClass('lw_selected')

      
      input
        .val('')
        .css('visibility', 'visible') # it must be visible to focus it
        .focus()
        .css('visibility', 'hidden')

      # cancel bubbling
      return false
    ).on('click', '.lw_multisuggest_remove', (e) ->
      e.preventDefault()

      $item = $(this).closest('.lw_multisuggest_item')

      # remove item if not locked
      if (!$item.is('.lw_locked'))
        $item.remove()
        input.css('visibility', 'visible').show(0)

      # trigger the change event on the suggestor
      self.trigger('change')

      # trigger the change event on the suggestor
      self.trigger('remove_multisuggest')

      return false
    ).on('click', '.lw_multisuggest_suggestions li', (e) ->
      id = $(this).find('input').val()
      existing = self.find('.lw_multisuggest_item input[value=' + id + ']').parent()

      if (!existing.length)
        self.multisuggest 'add',
          title: $.trim($(this).text())
          id: id

        if (!opts.onlyone)
          input.val('').focus()
        else
          input.val('').hide(0)
      else
        existing.addClass('lw_selected')
        input.val('').focus().css('visibility', 'hidden')

      return false # cancel bubbling
    )

    # .blur() doesn't QUITE work here that's why we have to have an annoying 200ms timeout
    input.blur(->
      self.find('.lw_multisuggest_item.lw_selected').removeClass('lw_selected')
      lastquery = ''
      hidesuggestions = setTimeout( ->
        # hide the suggestion popup (we can't hide it earlier, in case the user has clicked it)
        $suggestions.hide()

        # we do the following inside the timer in case clicking on a suggestion has already selected a result
        if (input.val())
          e = $.Event('keydown') # create a fake keydown event
          e.which = 13 # in which the 'return' key is pressed
          input.trigger(e) # and trigger it
      , 200)
    )
    # on each keypress, filter the results
    .keyup((e) ->
      # grab query, sanitize it // TODO COMPILE THESE REGEXPS
      query = $.trim($(this).val().toLowerCase().replace(/[,\-\/\s]+/g, ' ').replace(/[^a-zA-Z 0-9\.]+/g, ''))
      
      # do nothing if the query is unchanged
      return false if (query === lastquery)

      # empty and hide the suggestions list
      $suggestions.empty().hide()

      # if this query is NOT a subset of the last query, reinitialize the matches and search on all terms
      if (query.indexOf(lastquery) !== 0 || !lastquery.length)
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
      query_exp = new RegExp('(\\b' + query.replace(/\s/g, '|\\b') + ')', 'ig') # for highlighting the query terms
      if (results.length)
        $.each(results, (index, item) -> # list the match, with highlighting
          $suggestions.append('<li ' + (query === item.keywords ? 'class="lw_selected"' : '') + '><input type="hidden" value="' + item.id + '"/>' + (' ' + item.title).replace(query_exp, '<span class="lw_multisuggest_highlight">$1</span>') + '</li>')
        )
        position = input.position()
        $suggestions.css(
          left: position.left + 'px'
          top: position.top + 'px'
        ).show()

        # force select the first item if creation is disabled
        if (!opts.create) 
    )

    # capture special keys on keydown
    .keydown((e) -> 
      selected_item = self.find('.lw_multisuggest_item.lw_selected')

      # First, handle the case of a selected item
      if (selected_item.length)
        switch (e.which)
          when 13
            # enter/return
          when 32
            # space
            e.preventDefault()
            item = selected_item.find('.lw_item_name').text()
            selected_item.find('.lw_multisuggest_remove').trigger('click') # remove the item
            input.val(item).keyup() # and enter the item for editing
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
          when 39
            # right arrow
          when 9
            # tab
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
            # 
            self.find('.lw_multisuggest_item.lw_selected').removeClass('lw_selected') # deselect any selected items
            break

        input.css('visibility', 'visible') # and show the input
        return

      # remove previous suggestions that were not selected this time
      suggestall = -> 
        $suggestions.empty()
        if (opts.data.length)
          $.each opts.data, (index, item) ->
            $suggestions.append('<li><input type="hidden" value="' + item.id + '"/>' + item.title + '</li>')

          position = input.position()
          $suggestions.css(
            left: position.left + 'px'
            top: position.top + 'px'
          ).show()

      $selected = $suggestions.find('.lw_selected')

      # Otherwise, handle the autocomplete
      switch (e.which)
        when 38:
          # up arrow
          e.preventDefault()
          if ($suggestions.is(':hidden')) suggestall() # if there are no matches, show all matches
          match = $selected.find("span").text().toLowerCase()
          input_val = $.trim(input.val().toLowerCase())

          # if there's only one result and it's a match, don't let users deselect it
          if ($selected.siblings().length === 0 && input_val === match)
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
        when 40:
          # down arrow
          e.preventDefault()

          if ($suggestions.is(':hidden')) then suggestall() # if there are no matches, show all matches
          
          match = $selected.find("span").text().toLowerCase()
          input_val = $.trim(input.val().toLowerCase())

          # if there's only one result and it's a match, don't let users deselect it
          if ($selected.siblings().length === 0 && match === input_val)
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
        when 13:
          # enter/return
        when 44:
          # comma
        when 188:
          # comma again, some versions of jQuery return 188 for comma
        when 9:
          # tab
          if (e.which === 13) e.preventDefault() # always prevent enter

          # disable adding item with comma if we're not editing tags
          if (opts.type !== 'tags' && (e.which === 44 || e.which === 188))
            break

          existing = []
          if ($selected.length)
            e.preventDefault()

            id = $selected.find('input').val() # selected item id

            existing = self.find('.lw_multisuggest_item input[value=' + id + ']').parent()
            if (!existing.length)
              self.multisuggest 'add',
                title: $.trim($selected.text())
                id: id
          else
            # if there are no matches but creation is disabled
            if (!opts.create)
              return true

            value = $.trim(input.val())

            if (value.length)
              lcvalue = value.toLowerCase()
              existing = self.find('.lw_multisuggest_item .lw_multisuggest_item_name').filter(->
                # match if the string matches the value
                return $.trim($(this).text().toLowerCase()) === lcvalue 
              ).parent()

              if (!existing.length)
                e.preventDefault()
                self.multisuggest('new', value)

          input.val('').keyup()
          $suggestions.hide()

          if (existing.length)
            existing.addClass('lw_selected')
            input.css('visibility', 'hidden')

          break
        when 37:
          # left arrow
        when 8:
          # del/backspace
          # if there's no input, but there are older suggestions
          if (!$.trim(input.val()).length && input.siblings('.lw_multisuggest_item').length)
            e.preventDefault() # cancel the keypress
            input
              .val('') # remove any spaces just in case
              .css('visibility', 'hidden') # hide the input
              .prev().addClass('lw_selected') # and select the last item
            $suggestions.empty().hide() # hide suggestions
          break
    )

    # when scrolling the suggestions
    $suggestions.scroll ->
      clearTimeout(hidesuggestions) # don’t hide the suggestions list
      input.focus() # and keep the focus in the input

    # if we need to preselect
    if (opts.selected.length)
      # with each preselected tag
      $.each opts.selected, ->
        if (this.id)
          self.multisuggest('add', this) # select it;
        else # otherwise
          self.multisuggest('new', this.title) # add it as a new tag

      # don't show input if onlyone is on and we have one
      if (opts.onlyone && opts.selected.length > 0)
        input.css('visibility', 'hidden').blur()

  add: (value) ->
    input.before('<div class="lw_multisuggest_item' + (value.is_locked ? ' lw_locked' : '') + '"><input type="hidden"' + (!value.is_locked ? ' name="' + opts.name + '[]"' : '') + ' value="' + value.id + '"><span class="lw_item_name">' + value.title + '</span><span class="lw_multisuggest_remove">×</span></div>')
    self.trigger('change.multisuggest') # trigger the change event on the suggestor
  new: (value) ->
    item = $('<div class="lw_multisuggest_item lw_multisuggest_new"><span class="lw_multisuggest_item_name">' + value + '</span><span class="lw_multisuggest_remove">×</span></div>').insertBefore(input)
    $('<input type="hidden" name="' + opts.name + '_added[]"/>').val($.trim(value)).prependTo(item)
    self.trigger('change.multisuggest') # trigger the change event on the suggestor
