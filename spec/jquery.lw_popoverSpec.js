describe('Popover Test', function() {

  it('Should have a lwPopever function', function() {
    expect(typeof $.fn.lwPopover).toEqual('function');
  });
  
  it('Should be callable', function() {
    var $pop = $('<div/>').lwPopover();
    expect($pop.length).toEqual(1);
  });

  // this is kind of fucking amazing
});
