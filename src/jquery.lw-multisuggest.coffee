$ = livewhale?.jQuery || window.jQuery

$.widget 'lw.multisuggest',
  options:
    name:      'name'
    data:      []
    type:      'items'
    create:    false
    selected:  []
    onlyone:   false
    showlink:  true
    zIndex:    null
    options:
      keywords: null
  _create: ->
    opts = @options
    $el  = @element
    that = this

    # add title to keywords and normalize
    $.each opts.data, ->
      keywords = if (@keywords) then ' ' + that._normalizeSearchText(@keywords) else ''
      @keywords = that._normalizeSearchText(@title) + keywords

    $suggestions = @$suggestions = $('<ul class="lw-suggestions"/>')
    $input = @$input = $('<input type="text" class="lw-input"/>')

    $el
      .addClass("lw-multisuggest lw-multisuggest-#{ opts.type } lw-false-input")
      .append($suggestions)
      .append($input)

    #if (opts.showlink and opts.data.length)
    showlink_text = 'Show all ' + opts.type
    if (opts.type is 'places') then showlink_text = 'or ' + showlink_text

    $('<a class="lw-showall" href="#"/>')
      .text(showlink_text)
      .insertAfter($el)
      .click (e)->
        e.preventDefault()
        that.open()
        return true

    # hide and remove lw-false-input class if places widget on event_edit page
    if (opts.type is 'places' && livewhale.page is 'events_edit')
      $el.addClass('lw-hidden').removeClass('lw-false-input')

    $el
      # any click in widget should deselect selected, and place cursor in input unless opts.onlyone
      .click( ->
        $el.find('.lw-item.lw-selected').removeClass('lw-selected')

        # only one is wanted, don't allow clicking in
        return false if (opts.onlyone and $el.find('.lw-item').length >= 1)

        # otherwise place cursor in input
        $input.css('visibility', 'visible').focus().keyup()
        return true
      )
      # item click handler - selects item
      .on('click', '.lw-item', (e) ->
        e.preventDefault()
        e.stopPropagation()

        # select clicked item
        $(this).addClass('lw-selected').siblings().removeClass('lw-selected')
        return true
      )
      # remove item click handler
      .on('click', '.lw-remove', (e) ->
        e.preventDefault()

        $item = $(this).closest('.lw-item')

        # do nothing if the item is locked
        return false if $item.is('.lw-locked')

        # remove item and show input
        $item.remove()
        $input.css('visibility', 'visible').show(0)

        # trigger the change event on the suggestor
        that._trigger('change')

        # trigger the change event on the suggestor
        that._trigger('remove_multisuggest')

        return false
      )
      # suggestion click handler
      .on('click', '.lw-suggestions li', (e) ->
        $this = $(this)
        id = $this.find('input').val()
        existing = $el.find('.lw-item input[value=' + id + ']').parent()

        # we're clearing the input val regardless of what happens
        $input.val('')

        # mark item selected if it exists, otherwise add it as a new item
        if (existing.length)
          existing.addClass('lw-selected')
          $input.focus().css('visibility', 'hidden')
        else
          that.addItem
            title: $.trim($this.text())
            id: id
          if (opts.onlyone) then $input.hide(0) else $input.focus()

        # cancel bubbling
        return false
      )

    # .blur() doesn't QUITE work here that's why we have to have an annoying 200ms timeout
    $input.focus( ->
      $el.addClass('on')
      return true
    )
    .blur( ->
      $el.removeClass('on')

      that.lastquery = ''
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
      query = $.trim( that._normalizeSearchText( $input.val()) )

      # do nothing if query is same as last
      return if (query is that.lastquery)

      results = that._search(query)

      # empty and hide the suggestions list if no results returned
      $suggestions.empty().hide()

      if (results?.length)
        # regex for highlighting the query terms
        query_exp = new RegExp('(\\b' + query.replace(/\s/g, '|\\b') + ')', 'ig')

        # list matches, with highlighting
        $.each(results, (index, item) ->
          $li = $('<li/>')
          if query is item.keywords then $li.addClass('lw-selected')
          title = (' ' + item.title).replace(query_exp, '<span class="lw-highlight">$1</span>')
          $suggestions.append($li.html('<input type="hidden" value="' + item.id + '"/>' + title))
        )

        # position and show suggestion box
        position = $input.position()
        $suggestions.css(
          left: position.left + 'px'
          top: position.top + 'px'
        ).show()

        # force select the first item if creation is disabled
        if (!opts.create)
          $suggestions.children(':first-child').addClass('lw-selected')
    )
    # capture special keys on keydown
    .keydown( (e) ->
      key = e.which

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


      scroll = (direction) ->
        $lis      = $suggestions.children()
        $selected = $lis.filter('.lw-selected')
        match     = $selected.find("span").text().toLowerCase()
        input_val = $.trim($input.val().toLowerCase())

        # if there's only one result and it's a match, don't let users deselect it
        if ($selected.siblings().length is 0 && match is input_val) then return

        $selected.removeClass('lw-selected')
        $next = if (direction is 'down') then $selected.next() else $selected.prev()

        if ($next.length)
          $selected = $next
        else
          $selected = if (direction is 'down') then $lis.eq(0) else $lis.eq($lis.length - 1)

        $selected.addClass('lw-selected')
        position = ($selected.position().top + $selected.outerHeight()) - ($suggestions.height() - $suggestions.scrollTop())
        if (position > 0) then $suggestions.scrollTop(position)

      # Otherwise, handle the autocomplete
      switch (key)
        # up arrow
        when 38
          e.preventDefault()
          if ($suggestions.is(':hidden')) then suggestall() # show all matches if there are no matches
          scroll('up')
          break
        # down arrow
        when 40
          e.preventDefault()
          if ($suggestions.is(':hidden')) then suggestall() # show all matches if there are no matches
          scroll('down')
          break
        # enter/return or comma or comma sometimes return by jQuery or tab
        when 13, 44, 188, 9
          # always prevent enter
          if (key is 13) then e.preventDefault()

          # disable adding item with comma if we're not editing tags
          if (opts.type isnt 'tags' && (key is 44 || key is 188)) then break

          existing = []

          $selected = $suggestions.find('.lw-selected')

          if ($selected.length)
            e.preventDefault()

            id = $selected.find('input').val() # selected item id

            existing = $el.find('.lw-item input[value=' + id + ']').parent()
            if (!existing.length)
              that.addItem
                title: $.trim($selected.text())
                id: id
          else
            # do nothing if no matches and creation is disabled
            return true if (!opts.create)

            value = $.trim($input.val())

            if (value.length)
              lc_value = value.toLowerCase()
              existing = $el.find('.lw-item .lw-name').filter(->
                # match if the string matches the value
                return $.trim($(this).text().toLowerCase()) is lc_value
              ).parent()

              if (!existing.length)
                e.preventDefault()
                that.addNewItem(value)

          $input.val('').focus().keyup()
          $suggestions.hide()

          if (existing.length)
            existing.addClass('lw-selected')
            $input.css('visibility', 'hidden')

          break
        when 37, 8
          # left arrow or del/backspace
          # if there's no input, but there are older suggestions
          if (!$.trim($input.val()) && $input.siblings('.lw-item').length)
            e.preventDefault() # cancel the keypress
            $input
              .val('') # remove any spaces just in case
              .css('visibility', 'hidden') # hide the input
              .prev('.lw-item')
              .addClass('lw-selected') # and select the last item
            $suggestions.empty().hide() # hide suggestions
          break
    )

    $(document).keydown( (e) ->
      $selected = $el.find('.lw-item.lw-selected')

      # do nothing if no item selected
      if (not $selected.length) then return

      # first, handle the case of a selected item
      switch (e.which)
        # enter/return or space
        when 13, 32
          e.preventDefault()
          item = $selected.find('.lw-name').text()
          $selected.find('.lw-remove').trigger('click') # remove the item
          $input.val(item).css('visibility', 'visible').focus().keyup() # and enter the item for editing
          break
        # left arrow
        when 37
          e.preventDefault()
          prev = $selected.prev('.lw-item')

          # select previous item and return if it exists
          if (prev.length)
            $selected.removeClass('lw-selected')
            prev.addClass('lw-selected')
          break
        # right arrow or tab
        when 39, 9
          e.preventDefault()
          next = $selected.removeClass('lw-selected').next('.lw-item')

          # select next item and return if it exists
          if (next.length)
            next.addClass('lw-selected')
          else
            $input.css('visibility', 'visible').focus()
          break
        # del/backspace
        when 8
          e.preventDefault()
          $selected.find('.lw-remove').trigger('click')
          break
        else
          # deselect any selected items
          that.find('.lw-item.lw-selected').removeClass('lw-selected')
          break

      # and show the input
      return true
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
          that.addItem(this)
        else # otherwise
          that.addNewItem(this.title)

      # don't show input if onlyone is on and we have one
      if (opts.onlyone && opts.selected.length > 0)
        $input.css('visibility', 'hidden').blur()
  setSelected: (selected) ->
    that = this
    @element.find('.lw-item:not(.lw-new)').remove()
    $.each(selected, (i, item) ->
      that.add(item)
    )
  getSelected: ->
    # build selected array
    selected = []

    @element.find('.lw-item:not(.lw-new)').each ->
      selected.push( $(this).data('item') )
    return selected
  open: ->
    if !@$overlay
      @initOverlay()

    # set selected
    @$overlay.find('.lw-items').multiselect('option', 'selected', @getSelected())

    # open the overlay
    @$overlay.overlay('open')
  _itemExists: (name, id) ->

  initOverlay: ->
    $el = @element
    opts = @options
    that = this
    $input = @input
    $suggestions = @suggestions

    overlay = """
      <div class="lw-multisuggest-overlay">
        <div class="lw-items"></div>
      </div>
      """
    footer = """
      <div>
      <button type="button" class="lw-save btn btn-primary">Use selected #{ opts.type }</button>
      <span class="lw-cancel">or <a href="#">cancel and close</a></span>
      </div>
      """
    $footer = $(footer)

    overlay_opts =
      closeSelector: '.lw-cancel a'
      title: 'All ' + opts.type
      footer: $footer
      destroyOnClose: false
      autoOpen: false

    if (opts.zIndex) then overlay_opts.zIndex = opts.zIndex

    @$overlay = $overlay = $(overlay).overlay(overlay_opts)

    # save items selected in overlay
    $footer.on('click', '.lw-save', ->
      #that.setSelected(that.$items.multiselect('getSelected'))
      if (!opts.onlyone or !selected.length)
        that.$input.css('visibility', 'visible').focus().keyup()

      $overlay.overlay('close')
      return false
    )

    # inti multiselect in overlay
    @$items = $overlay.find('.lw-items').multiselect
      type:      opts.type
      data:      opts.data
      onlyone:   opts.onlyone
      change: (e, data) ->
        if (data.action is 'select')
          that.addItem(
            id: data.item.id,
            title: data.item.title
          )
        if (data.action is 'deselect')
          that.removeItem(data.item.id)

        return true
  # value is an object with keys id and title
  addItem: (item, is_new) ->
    input_postfix = new_item_class = ""

    if (is_new)
      item.id = item.title
      input_postfix = '_added'
      new_item_class = ' lw-new'

    markup = """
      <div class="lw-item#{ new_item_class }">
        <input type="hidden" name="#{ @options.name }#{ input_postfix }[]" value="#{ item.id }" />
        <span class="lw-name">#{ item.title }</span>
        <span class="lw-remove">×</span>
      </div>
      """
    $item = $(markup).data('item', item)

    # class and remove name attribute from input if locked
    if (item.is_locked) then $item.addClass('lw-locked').find('input').removeAttr('name')

    # add the hidden input and trigger change event
    @$input.before($item)
    @_trigger('change')

    return @
  removeItem: (id) ->
    @element.find('.lw-item').each( ->
      $this = $(this)
      if ($this.data('item').id is id)
        $this.remove()
        return false
      return true
    )
    return @
  addNewItem: (title) ->
    return @addItem({ title: title, id: null }, true)
  add: (item) ->
    return @addItem(item)
  new: (title) ->
    return @addNewItem(title)
  _search: (query) ->
    $input = @$input
    results = []
    data = @options.data

    # do nothing if the query is unchanged
    return results if (!query or query is @lastquery)

    @lastquery = query # store the last query

    # filter the result for each word in the query
    $.each(query.split(' '), ->
      term = this
      results = $.grep data, (item) ->
        return (' ' + item.keywords).indexOf(' ' + term) >= 0
    )
    return results
  _normalizeSearchText: (string) ->
    return string
      .toLowerCase()
      .replace('&amp', 'and')
      .replace(/[,\-_\s&\/\\]+/g, ' ') # convert to spaces
      .replace(/[^a-zA-Z 0-9]+/g, '')  # remove non-alphanumeric chars
