$(function(){
  $('#url-input').on('paste', function(){
    setTimeout(function(){
      document.form.submit();
    },100)
  });
});
