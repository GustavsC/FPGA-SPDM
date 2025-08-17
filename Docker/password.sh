#!/usr/bin/expect -f

# Set timeout (in seconds) for expect
set timeout 20

# Set your Xilinx account email and password
set email "my-email@gmail.com"
set password "my-password"

# Start the AuthTokenGen command
spawn ./vivado-installer/extracted/xsetup -b AuthTokenGen

# Expect the email prompt and send the email
expect "Enter your Xilinx username (email):"
send "$email\r"

# Expect the password prompt and send the password
expect "Enter your Xilinx password:"
send "$password\r"

# Wait for the process to complete
expect eof
