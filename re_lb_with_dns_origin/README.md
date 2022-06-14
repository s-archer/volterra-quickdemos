# Deploy LB to F5 XC RE's with Origin defined by FQDN

Rename vars.tf.example to vars.tf and then update the variables as necessary.

For F5 XC API cert auth, obtain a new .p12 from the F5 XC console.  Store.  Reference the location in the `volt_api_p12_file` variable.  Then set the .p12 passphrase as ENV:

	export VES_P12_PASSWORD=<cert passphrase>