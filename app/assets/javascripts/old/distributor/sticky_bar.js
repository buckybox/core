$(function() {
  var sticky_nav = $('#sub-nav');
  var sticky_nav_parent = sticky_nav.parent();
  sticky_nav.sticky({ topSpacing: 0, getWidthFrom: sticky_nav_parent });
});
