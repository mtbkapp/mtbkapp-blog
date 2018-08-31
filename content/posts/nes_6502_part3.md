---
title: "Nerdy Nights Week 2 & 3"
date: 2018-08-31T10:03:25-06:00
draft: false 
tags: ["NES"]
---

I read the Nerdy Nights weeks 2 & 3 tutorials. I learned a lot more about
the NES Architecture, memory, and how the 6502 processor fits into everything. 

I'm not sure why I am surprised by this but it's interesting
to me that sending commands to the PPU (picture processing unit) is just writing
data to specific memory locations. For some reason I assumed that interfacing
with things outside the CPU would be via some specific instructions.

It was also interesting the way a piece of graphics is eventually rendered. 
Sprites and backgrounds have their own palettes each of 16 colors. To figure out
what color to put in a particular pixel the PPU computes an index into a palette
from the pattern table and the attribute table. It first takes an entry from 
the pattern table which is a section of memory of 2 bits per pixel of an 8x8 
pixel square, so 16 bytes. Each 2 bits are used as the lower two bits of the 
index. Then 2 bits are used from the attribute table as the high bits. The 4 
bits yields the index into a 16 color palette.

I then learned a bit about the syntax for an `asm` file for the `NESASM` 
assembler. There are directives, labels, opcodes, and comments. The 6502 
assembly language was mostly a review of what I learned in the Easy6502 
tutorial. I did learn that before `ADC` the carry flag should probably be 
cleared and before `SBC` it should probably be set. I haven't thought too much
about why yet. I was
thinking that `$ff + $ff` are the two biggest numbers you can add via 2 8 bit
integers which is `$1fe` which would only need 1 bit to indicate the `$100` 
part. All other additions would result a smaller number either needing the bit
or not. I assume underflow is similar.  The NES' 6502 doesn't have decimal 
mode so it's just integers.

Finally I downloaded the demo code that shows how to setup what code is run at 
start up and when the reset button is pressed.  As well as when the PPU is in "V Blank" 
(waiting for the CRT scanner to go from the bottom of the screen to the top).
The demo code for reset does a bunch memory clearing and then enters a infinite
loop. It turns off `NMI` (the vblank interrupt) and sets the screen. I wonder
if one way to set things up is the have the reset code enter an infinite loop
at the end of it's routine but enable NMI right before. Then the NMI interrupt
is fired by the PPU and the NMI code can update graphics and then resume the 
infinite loop. However this assumes all the work to produce the next frame can
be done in vblank and not need to do any work while the frame is being drawn.

The last bit of info I figured out was that the FCEUX emulator/debugger doesn't
have debugging in the Linux version. So I uninstalled that and downloaded win32
version which runs via Wine. Not sure if that'll work longer term but hopefully.
Running the demo program sort of locks up my VM which is a bummer--need to 
figure that out. Already tried increasing the CPU count for it from 1 to 2. I 
wonder if there is some other VM or emulator settings that can help...

20 min / day... not enough.
