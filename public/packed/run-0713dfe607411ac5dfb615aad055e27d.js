$(function() {
  $('body').scrollspy({
    target: '.bs-docs-sidebar',
    offset: 10
  });

  $('#select2-domain').select2();
  $('#select2-domain').on("change",function(){
    var id = '#s-domain-list-' +$(this).val();
    $('#none').prop('selected', true);
    $('html, body').animate({
      scrollTop: $(id).offset().top
     }, 200);
  });

  $('#select2-user').select2();
  $('#select2-user').on("change",function(){
    var id = '#s-user-list-' +$(this).val();
    $('#none').prop('selected', true);
    $('html, body').animate({
      scrollTop: $(id).offset().top
     }, 200);
  });

  $('#login-btn').on("click",function(){
    $('html, body').animate({
      scrollTop: $('#auth').offset().top
     }, 300);
  });

  $('#i-search').select2();
  $('#i-search').on("change",function(){
    var id = '#' +$(this).val();
    $('#none').prop('selected', true);
    $('html, body').animate({
      scrollTop: $(id).offset().top
     }, 200);
  });

  $('.form-validate').bootstrapValidator({
    feedbackIcons: {
      valid: 'glyphicon glyphicon-ok',
      invalid: 'glyphicon glyphicon-remove',
      validating: 'glyphicon glyphicon-refresh'
    }
  });
});
