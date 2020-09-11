$(document).ready(function() {


	/* ======= responsive pricing table ======== */
	$('#pricing-tabs .pricing-tab').on('click', function(e){
		e.preventDefault();
		if (!$(this).hasClass('active')) {
			$(this).addClass('active').siblings().removeClass('active');
		}
		
		$PricingData = $(this).attr('data-target');
		
		//console.log(($PricingData));
		
	    $('#pricing-table').find('.'+ $PricingData).show().siblings().not('.pricing-0-data').hide();
		
				
	});
	
	
	/* ======= FAQ accordion ======= */
    $('.card-toggle').on('click', function () {
      if ($(this).find('svg').attr('data-icon') == 'chevron-down' ) {
        $(this).find('svg').attr('data-icon', 'chevron-up');
      } else {
        $(this).find('svg').attr('data-icon', 'chevron-down');
      };
    });
	


});



