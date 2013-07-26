// do not require store/spree_core cause it loads all spree standard js files

  $(document).ready(function(){

  	/*$.validator.addMethod(
        "zipcode",
        function(value, element) {
            return this.optional(element) || /^[0-9]{4,5}$/.test(value);
    });*/

    $.validator.addMethod(
		"phone", 
		function(value, element) {
			return this.optional(element) || /^[0-9/. \-]*$/.test(value);
	});
	
	$("#account_form_address").validate();
	
	/*

    $("#account_form_address").validate({
	  rules: {
	    'address[zipcode]': {
	      	required: true,
	      	postalcode: true
	    },
	    'address[phone]': {
	    	required: true,
	    	phone: true
	    }
	  }
	});
	
	*/
	
  });

(function($) {
  $(document).ready(function(){
    if ($(".select_address").length) {
      $('input#order_use_billing').unbind("click");
      $("#billing .inner").hide(); //$(".inner").hide();
      // $(".inner input").prop("disabled", true);
      // $(".inner select").prop("disabled", true);
      $("#billing .inner input").prop("disabled", true);
      $("#billing .inner select").prop("disabled", true);
      if ($('input#order_use_billing').is(':checked')) {
        $("#shipping .shippingAaddress").hide();
      }
      
      $('input#order_use_billing').click(function() {
        if ($(this).is(':checked')) {
          $("#shipping .shippingAddress").hide();
          hide_address_form('shipping');
        } else {
          $("#shipping .shippingAddress").show();
          if ($("input[name='order[ship_address_id]']:checked").val() == '0') {
            show_address_form('shipping');
          }
        }
      });

      $("input[name='order[bill_address_id]']:radio").change(function(){
        if ($("input[name='order[bill_address_id]']:checked").val() == '0') {
          show_address_form('billing');
        } else {
          hide_address_form('billing');
        }
      });

      $("input[name='order[ship_address_id]']:radio").change(function(){
        if ($("input[name='order[ship_address_id]']:checked").val() == '0') {
          show_address_form('shipping');
        } else {
          hide_address_form('shipping');
        }
      });
    }
  });
  
  function hide_address_form(address_type){
    $("#" + address_type + " .inner").hide();
    $("#" + address_type + " .inner input").prop("disabled", true);
    $("#" + address_type + " .inner select").prop("disabled", true);
  }
  
  function show_address_form(address_type){
    $("#" + address_type + " .inner").show();
    $("#" + address_type + " .inner input").prop("disabled", false);
    $("#" + address_type + " .inner select").prop("disabled", false);
  }
})(jQuery);
