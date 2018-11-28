#!/usr/bin/expect -f
spawn ./vote.sh
expect "*What do you like better*"
send "\033\[A"
send -- "\r"
interact
