# RPiet - Ruby implementation of Piet programming language

Check it out: http://www.dangermouse.net/esoteric/piet.html

This is a pretty naive implementation, but it can run things like fib:

[[/tree/master/images/helloworld-pietbig.gif|align=center]]

## Running

jruby -Ilib ./bin/rpiet --debug images/nfib.png

Or an image from the net:

jruby -Ilib bin/rpiet -c 8 http://www.retas.de/thomas/computer/programs/useless/secunet_contest/entry_3/s2_8.gif
