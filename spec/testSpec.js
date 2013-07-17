describe('Motherfucking Test', function() {
  var $x = $('<div/>').text('fuck yeah');

  it('should fuck off', function() {
    expect($x.length).toEqual(1);
  });

  it('should say hello', function() {
    var test = new Test();
    expect(test.hello()).toEqual('Hello');
  });
});
