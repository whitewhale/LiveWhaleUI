describe('Hoverbox Test', function() {

  it('Should have a lwHoverbox function', function() {
    expect(typeof $.fn.lwHoverbox).toEqual('function');
  });
  
  it('Should be callable', function() {
    var $pop = $('<div/>').lwHoverbox();
    expect($pop.length).toEqual(1);
  });

  // this is kind of fucking amazing
});
