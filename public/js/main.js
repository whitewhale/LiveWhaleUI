// Generated by CoffeeScript 1.6.3
(function() {
  var $, body_id, page;

  $ = livewhale.jQuery;

  page = {
    timepicker: {
      init: function() {
        var $picker;
        $picker = $('#picker').timepicker();
        $('#format_toggle').click(function(e) {
          var format, show24;
          e.preventDefault();
          show24 = $picker.timepicker('option', 'show24Hours') ? false : true;
          format = $picker.timepicker('option', 'show24Hours', show24);
          return true;
        });
      }
    },
    overlay: {
      init: function() {
        var $overlay;
        $overlay = $('#overlay_content').overlay({
          autoOpen: false,
          destroyOnClose: false
        });
        $('#overlay_open').click(function() {
          $overlay.overlay('open');
          return true;
        });
        $('#change_width').change(function() {
          $overlay.overlay('option', 'width', $(this).val());
          return true;
        });
      }
    },
    popover: {
      init: function() {
        var $right;
        $('.open_top').popover({
          position: 'top',
          html: '<p>Hello World!</p>'
        });
        $('.open_bottom').popover({
          position: 'bottom',
          html: '<p>Hello World!</p>'
        });
        $('.open_left').popover({
          position: 'left',
          html: '<p>Hello World!</p>'
        });
        $right = $('.open_right').popover({
          position: 'right',
          html: '<p>Hello World!</p>'
        });
        return $('#delegation_links').on('click', 'a', function(e) {
          var $target;
          e.preventDefault();
          $target = $(e.target);
          if ($target.hasClass('lwui-widget')) {
            return true;
          }
          e.stopPropagation();
          return $target.popover({
            autoOpen: true,
            beforeOpen: function() {
              var $this;
              $('body').click();
              $this = $(this);
              return $this.popover('html', $this.attr('data-text'));
            },
            close: function() {
              return $(this).popover('destroy');
            }
          });
        });
      }
    },
    slideshow: {
      init: function() {
        $('.slideshow_top').slideshow({
          controlPlacement: 'prepend'
        });
        return $('.slideshow_bottom').slideshow();
      }
    }
  };

  body_id = $('body').attr('id');

  if (page[body_id]) {
    page[body_id].init();
  }

}).call(this);
