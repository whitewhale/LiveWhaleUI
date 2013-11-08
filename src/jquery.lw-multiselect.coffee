$ = livewhale?.jQuery || window.jQuery

$.widget 'lw.multiselect',
  # default options
  options: {
    name: 'name',
    data: [],
    type: 'items',
    selected: [],
    onlyone: false
  },
  _create: ->
    that = this
    opts = this.options
    $ul

    # add the multiselector parent
    this.element.append('<div class="lw_multiselect lw_multiselect_' + opts.type + '"/>')

    $ul = $('<ul/>').appendTo(this.element.children().eq(0))

    $.each opts.data, (index, item) ->
      $ul.append('<li' + (item.size ? ' style="font-size:' + item.size + 'em;"' : '') + '><input type="checkbox" value="' + item.id + '" name="' + opts.name + '[]" id="lw_multiselect_' + opts.name + '_' + item.id + '"/><label class="lw_multiselect_item" for="lw_multiselect_' + opts.name + '_' + item.id + '"><span class="lw_item_name">' + item.title + '</span></label></li>')

    # highlight preselected items 
    this._highlightSelected()

    # handle item click 
    this.element.on 'click', '.lw_multiselect_item', ->
      # return right away if this item is locked
      if ($(this).is('.lw_locked'))
        return false

      # highlight clicked and de-select others if opts.onlyone, otherwise toggle clicked 
      if (opts.onlyone)
        $('.lw_multiselect_item').removeClass('lw_selected')
        $(this).addClass('lw_selected')
      else
        $(this).toggleClass('lw_selected')
  _highlightSelected: ->
    that    = this
    opts    = this.options
    sel_tbl = {}

    # return righ away if nothing selected
    if (!opts.selected.length)
      return false

    # create lookup table from opts.selected array, which is an array of objects with id, title, is_locked 
    $.each opts.selected, (i, val) ->
      sel_tbl[val.id] = val

    this.element.find('input[type="checkbox"]').each (index, el) ->
      $input    = $(el)
      input_val = $input.attr('value')
      $label    = $input.siblings('.lw_multiselect_item')

      # mark selected if the input value contains a key in selected lookup table 
      if (input_val && input_val in sel_tbl)
        $input.prop('checked', true)
        $label.addClass('lw_selected')

        if (sel_tbl[input_val].is_locked)
          $label.addClass('lw_locked')
  # remove lock class from all lis 
  unlockAll: ->
    this.element.find('.lw_multiselect_item').removeClass('lw_locked')
  # add lock class to all lis 
  lockAll: ->
    this.element.find('.lw_multiselect_item').addClass('lw_locked')
  selectAll: ->
    this.element.find('input').prop('checked', true)
    this.element.find('.lw_multiselect_item').addClass('lw_selected')
  selectNone: ->
    this.element.find('input').prop('checked', false)
    this.element.find('.lw_multiselect_item').removeClass('lw_selected')
  resetSelection: ->
    this.selectNone()
    this._highlightSelected()
  _setOption: $.noop,
  _destroy: ->
    this.element.find('.lw_multiselect').remove()
