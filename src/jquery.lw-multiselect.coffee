$ = livewhale?.jQuery || window.jQuery

$.widget 'lw.multiselect',
  # default options
  options: {
    name:      'name',
    data:      [],
    type:      'items',
    selected:  [],
    onlyone:   false
  },
  _create: ->
    $el  = @element
    that = this
    opts = this.options
    items = ''

    # add the multiselector parent
    $el.addClass("lw-multiselect lw-multiselect-#{ opts.type }")

    $.each opts.data, (index, item) ->
      items += """ 
        <li class="lw-item">
          <input type="checkbox" value="#{ item.id }" name="#{ opts.name }[]" />
          <span class="lw-name">#{ item.title }</span>
        </li>
        """

    @$ul = $ul = $('<ul/>').html(items).appendTo($el)

    # highlight preselected items 
    this._highlightSelected()

    # handle item click 
    $el.on 'click', '.lw-item', (e) ->
      e.preventDefault()

      $this = $(this)

      # return right away if this item is locked
      return false if ($this.is('.lw-locked'))

      # highlight clicked and de-select others if opts.onlyone, otherwise toggle clicked 
      if (opts.onlyone)
        that.deselectAll()
        $this.addClass('lw-selected')
      else
        $this.toggleClass('lw-selected')

      # set check status on hidden checkbox input
      $this.find('input').prop('checked', $this.hasClass('lw-selected'))

      return true
  _highlightSelected: ->
    that    = this
    opts    = @options
    sel_tbl = {}

    # return righ away if nothing selected
    if (!opts.selected.length)
      return false

    # create lookup table from opts.selected array, which is an array of objects with id, title, is_locked 
    $.each opts.selected, (i, val) ->
      sel_tbl[val.id] = true

    @$ul.children().each (index, el) ->
      $li    = $(el)
      $input = $li.find('input')
      id     = parseInt($input.val(), 10)

      # mark selected if the input value contains a key in selected lookup table 
      if (id and sel_tbl[id]?)
        $input.prop('checked', true)
        $li.addClass('lw-selected')

        if (sel_tbl[id].is_locked)
          $li.addClass('lw-locked')
  # remove lock class from all lis 
  unlockAll: ->
    @$ul.children().removeClass('lw-locked')
  # add lock class to all lis 
  lockAll: ->
    @$ul.children().addClass('lw=locked')
  selectAll: ->
    @$ul.find('input').prop('checked', true)
    @$ul.children().addClass('lw-selected')
  deselectAll: ->
    @$ul.find('input').prop('checked', false)
    @$ul.children().removeClass('lw-selected')
  resetSelection: ->
    @selectNone()
    @_highlightSelected()
  _setOption: $.noop,
  _destroy: ->
    @element
      .removeClass("lw-multiselect")
      .removeClass("lw-multiselect-#{ @options.type }")
      .off 'click', '.lw-item'
    @$ul.remove()
