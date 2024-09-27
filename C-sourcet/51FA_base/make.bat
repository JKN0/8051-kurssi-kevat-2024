sdcc -c --model-small --no-xinit-opt --iram-size 256 --xram-size 0x2000 main.c
sdcc -c --model-small --no-xinit-opt --iram-size 256 --xram-size 0x2000 tasks.c
sdcc --model-small --no-xinit-opt --iram-size 256 --xram-size 0x2000 --code-loc 0x2000 -o 51FA_base.ihx main.rel tasks.rel
