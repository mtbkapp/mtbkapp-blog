---
title: "Nerdy Nights Week 4"
date: 2018-09-10T10:01:23-06:00
draft: false 
tags: ["NES"]
---

Today I learned about color palettes and sprites. I also learned about a general
strategy for updating graphics. The strategy appears to keep sprite data from
`$0200` to `$02ff`. Then on NMI update data to set the tile, position, and
several other attributes of sprites that need to change. Then setup a DMA 
transfer of this memory block to the PPU's sprite memory. 

I was able to edit the demo code to have the tile and positions of a couple of
sprites change on every NMI. State management may be tricky depending on how
complicated the Moon Lander game becomes.

I had some ideas about a DSL for NES dev so that I don't have to keep so much 
in my head. Things like, memory addresses for things, memory layouts, etc. I
could use the same parsing/compiling strategy I've used in the past to use 
Clojure readable things as language elements. Then use Clojure Spec to define
the grammar and parser. Then write code to take the "conformed" data structure
and have it write out the assembly code and call the assembler. However, I'm 
going to start with regular assembly for the first version of Moon Lander game.

[Nerdy Nights Week 4](http://nintendoage.com/forum/messageview.cfm?catid=22&threadid=6082)
