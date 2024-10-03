sdcc -c --model-small --no-xinit-opt --iram-size 256 --xram-size 0x2000 main.c
sdcc -c --model-small --no-xinit-opt --iram-size 256 --xram-size 0x2000 tasks.c
sdcc -c --model-small --no-xinit-opt --iram-size 256 --xram-size 0x2000 lcd.c
sdcc --model-small --no-xinit-opt --iram-size 256 --xram-size 0x2000 --code-loc 0x2000 -o clock_demo.ihx main.rel tasks.rel lcd.rel
