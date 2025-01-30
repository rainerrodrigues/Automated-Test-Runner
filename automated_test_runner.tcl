# Automated Test Runner Script in Tcl

# Configuration
set test_cases {
	"test_case_1.tcl"
	"test_case_2.tcl"
	"test_case_3.tcl"
}

set log_file "test_runner.log"
set report_file "test_report.txt"
set email_notifications true
set email_recipient "rainerrodrigues16@gmail.com"
set smtp_server "smtp.gmail.com"
set smtp_port 587
set smtp_username "rainerrodrigues16@gmail.com"
set smtp_password "*******"

# Procedure : log_message
proc log_message {message} {
	set timestamp [clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"]
	puts "$timestamp - $message"
	append_to_file #::log_file "$timestamp - $message\n"
}

proc append_to_file {file_path content} {
	set fp [open $file_path "a"]
	puts $fp $content
	close $fp
}

# Procedure : run_test_case
proc run_test_case {test_file} {
	log_message "Starting test case: $test_file"
	set result [catch {exec tclsh $test_file} output]
	if {$result == 0} {
		log_message "Test case $test_file passed."
		return [list "PASSED" $output]
	} else {
		log_message "Test case $test_file failed: $output"
		return [list "FAILED" $output]
	}
}

# Run all test cases and generate results
proc run_all_tests {} {
	log_message "Starting test suite execution ..."
	set passed 0
	set failed 0
	set results {}

	#Clear previous report
	set fp [open $::report_file "w"]
	close $fp

	foreach test_case $::test_cases {
		lassign [run_test_case $test_case] status output
		# set [list status output] [run_test_case $test_case]
		if {$status eq "PASSED"} {
			incr passed
		} else {
			incr failed
		}
		lappend results [list $test_case $status $output]
	}

	# Generate report
	set report "\n Test Suite Results\n================\n"
	append report "Total Tests: [expr {$passed + $failed}]\n"
	append report "Passed: $passed\nFailed: $failed\n\n"
	foreach result $results {
		lassign $result test_case status output
		append report "Test Case: $test_case\nStatus: $status\nOutput:\n$output\n\n"
	}
	append_to_file $::report_file $report

	log_message "Test suite completed. Report generated at $::report_file."
	return $report
}

#Send email notification
proc send_email {subject body} {
	package require smtp
	package require mime
	package require tls ;#Ensure TLS support
	
	# Initialize the email with the body as a string
	set token [mime::initialize -string $body]

	# Set the email headers
	mime::setheader $token Subject $subject
	mime::setheader $token From $::smtp_username
	mime::setheader $token To $::email_recipient
	# set messsage [mime::initialize -headers {
	#	Subject $subject
	#	From $::smtp_username
	#	To $::email_recipient }	]
	# mime::setmessage $message $body
	
	# Send the email
	if {[catch {
		smtp::sendmessage $token \
			-recipients $::email_recipient \
			-servers $::smtp_server \
			-username $::smtp_username \
			-password $::smtp_password \
			-usetls 1
	} err]} {
		puts "Failed to send email: $err"
	} else {
		puts "Email sent successfully!"
	}
	# Cleanup MIME token
	mime::finalize $token

	#log_message "Email sent to $::email_recipient."
}

proc main {} {
	# Clear logs
	set fp [open $::log_file "w"]
	close $fp

	log_message "Automated Test Runner started."

	#Run tests
	set report [run_all_tests]
	
	#Send email notification
	if {$::email_notifications} {
		log_message "Sending email notification..."
		send_email "Test Suite Results" $report
	}

	log_message "Automated Test Runner completed."
}

main
	
