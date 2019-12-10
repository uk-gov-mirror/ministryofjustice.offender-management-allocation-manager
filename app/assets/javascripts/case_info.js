$(document).ready(function () {
  $('input[type="radio"][data-behavior="last-address"]').click(function (evt) {
    if ($(this).val() == "Northern Ireland" || $(this).val() == "Scotland") {
      $('.optional-case-info').hide();
    } else {
      $('.optional-case-info').show();
    }
  });
});

$(document).on('turbolinks:load', function(){
    if((document.getElementById('case_information_probation_service_scotland').checked) || (document.getElementById('case_information_probation_service_northern_ireland').checked)){
        $('.optional-case-info').hide();
    }else if((document.getElementById('case_information_last_known_address_no').checked) || (document.getElementById('case_information_probation_service_wales').checked)) {
        $('.optional-case-info').show();
    }
});
