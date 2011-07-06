function init_input(input, message) {
	reset_input(input, message)

	input.click(function(e) {
		$(this).val('').css('color', 'black')
	})
	input.blur(function(e) {
		reset_input(input, message)
	})
}

function reset_input(input, message) {
	if(input.val() == "") {
		input.val(message).css('color', 'grey')
	}
}
