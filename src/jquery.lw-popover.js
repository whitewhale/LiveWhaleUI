/* lwPopover plugin */ 

var livewhale = livewhale || {};

;(function($) {

  $.widget('lw.lwPopover', {
    // default options
    options: {
      position:   'top',   // possible options are left, right, top, bottom
      width:      'auto',
      height:     'auto',
      autoOpen:   true,
      maxWidth:   null,
      maxHeight:  null,
      html:       null,
      text:       null,
      distance:   5,
      xpos:       null,   // force popover to oper at xpos
      ypos:       null    // force popover to open at ypos
    },
    // init widget
    _create: function() {
      var that  = this,
          el    = this.element,
          opts  = this.options,
          $body = $('body'),
          coords;

      this.$content = $('<div/>').addClass('lw_popover_content');
      this.$pointer = $('<div/>').addClass('lw_popover_pointer');

      this.$popover = $('<div/>', {
        'class': 'lw_popover lw_hidden lw_popover_pos_' + opts.position,
        width: opts.width,
        height: opts.height
      }).append(this.$pointer).append(this.$content).appendTo($body);

      if (opts.maxWidth) {
        this.$popover.css('max-width', parseInt(opts.maxWidth, 10) + 'px');
      }
      if (opts.maxHeight) {
        this.$popover.css('max-height', parseInt(opts.maxHeight, 10) + 'px');
      }

      // set content
      if (opts.html) {
        this.$content.html(opts.html);
      }

      // position and show
      if (true === opts.autoOpen) {
        this.open();
      }

      // for filtering click that initiated plugin creation
      this.first_click = true;

      // handler to destroy instance when popover is closed
      this.close_handler = function(evt) {
        var $target = $(evt.target);

        // don't close popover if click within popover
        if ($target.closest('.lw_popover').length) return false;

        // also don't close on the first click in which the target element is the same as the 
        // plugin's element.  we need to do this because the plugin is designed to be used in 
        // conjunction with event delegation, where the plugin is created on an item the user 
        // clicks.  If we don't do the following, the click that creates the plugin will bubble 
        // up to the body element and trigger the body click handler we define below which 
        // destroys the plugin.
        if (that.first_click && $target.get(0) === el.get(0)) {
          that.first_click = false;
          return false;
        }

        evt.preventDefault();
        that.close();

        return true;
      };

      // defining handler as an object property allows us to unbind this specific handler
      $body.bind('click', this.close_handler);
    },
    position: function() {
      var el             = this.element,
          opts           = this.options,
          el_offset      = el.offset(),
          adjustment     = 10 - opts.distance, // 10 is the number of pixels in pointer png beyond tip
          pointer_width  = 22,
          pointer_height = 22,
          pos, xpos, ypos, pointer_xpos, pointer_ypos;

      pos = opts.position || 'top';

      // switch to opposite position if not room enought at client specified location
      // this is not tested
      if ('top' === pos && (this.$popover.outerHeight() + pointer_height + adjustment) > el_offset.top) {
        pos = 'bottom';
      } else if ('bottom' === pos && (this.$popover.outerHeight() + pointer_height + adjustment) > el_offset.bottom) {
        pos = 'top';
      } else if ('left' === pos && (this.$popover.outerWidth() + pointer_width + adjustment > el_offset.left)) {
        pos = 'right';
      } else if ('right' === pos && (this.$popover.outerWidth() + pointer_width + adjustment > $(window).width() - el_offset.left)) {
        pos = 'left';
      } 

      switch (opts.position) {
        case 'top':
          ypos = el_offset.top - pointer_height - this.$popover.outerHeight() + adjustment;
          xpos = (opts.xpos) 
               ? opts.xpos - this.$popover.outerWidth() / 2
               : el_offset.left - this.$popover.outerWidth() / 2 + el.outerWidth() / 2;
          pointer_xpos = this.$popover.outerWidth() / 2 - pointer_width / 2;
          pointer_ypos = this.$popover.outerHeight() - 2;
          break;
        case 'bottom':
          ypos = el_offset.top + el.outerHeight() + pointer_height - adjustment;
          xpos = (opts.xpos) 
               ? opts.xpos - this.$popover.outerWidth() / 2
               : el_offset.left - this.$popover.outerWidth() / 2 + el.outerWidth() / 2;
          pointer_xpos = this.$popover.outerWidth() / 2 - pointer_width / 2;
          pointer_ypos = 0 - pointer_width;
          break;
        case 'left':
          ypos = (opts.ypos) 
               ? opts.ypos - this.$popover.outerHeight() / 2
               : el_offset.top - this.$popover.outerHeight() / 2 + el.outerHeight() / 2;
          xpos = el_offset.left - this.$popover.outerWidth() - pointer_width + adjustment;
          pointer_xpos = this.$popover.outerWidth() - 2;
          pointer_ypos = this.$popover.outerHeight() / 2 - pointer_height / 2;
          break;
        case 'right':
          ypos = (opts.ypos) 
               ? opts.ypos - this.$popover.outerHeight() / 2
               : el_offset.top - this.$popover.outerHeight() / 2 + el.outerHeight() / 2;
          xpos = el_offset.left + el.outerWidth() + pointer_width - adjustment;
          pointer_xpos = 0 - pointer_width;
          pointer_ypos = this.$popover.outerHeight() / 2 - pointer_height / 2;
          break;
        default:
          break;
      }

      // position pointer
      this.$pointer.css({
        top: pointer_ypos,
        left: pointer_xpos
      });

      // position popover
      this.$popover.css({
        top: ypos,
        left: xpos
      });
    },
    append: function(el) {
      this.$content.append(el);
    },
    open: function () {
      this.position();
      this.$popover.removeClass('lw_hidden');
    },
    close: function() {
      this._trigger('close');
      this.destroy();
    },
    _destroy: function(callback) {
      // clean up
      this.$popover.remove();
      $('body').unbind('click', this.close_handler);
    }
  });

}(livewhale.jQuery || jQuery));
