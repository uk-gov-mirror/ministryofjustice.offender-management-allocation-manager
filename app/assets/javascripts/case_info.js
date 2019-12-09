$(document).ready(function () {
  $('input[type="radio"][data-behavior="last-address"]').click(function (evt) {
    if ($(this).val() == "Northern Ireland" || $(this).val() == "Scotland") {
      $('.optional-case-info').hide();
    } else {
      $('.optional-case-info').show();
    }
  });
});
