$(function() {
  $('article').each(function(index, article) {
    window.setTimeout(function() {
      $(article).addClass('spawn');
    }, index * 250);
  });
});
