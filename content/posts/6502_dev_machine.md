---
title: "Initial NES / 6502 Dev Machine Setup"
date: 2018-08-29T14:19:31-04:00
draft: false 
tags: ["NES"]
---

I looked for lists online of tools I'll need to build my Moon Lander game and 
found the following from 
[FRITZVD](http://blog.fritzvd.com/2016/06/13/Getting-started-with-NES-programming/).
Below is what I've got setup so far:

1.  VirtualBox VM w/ the minimal install of Ubuntu Mate (Mate is lightweight 
and runs well in a VM)
1.  Default *gVim* from `apt`
1.  My Vim setup from my [`kapp-vim` repo](https://github.com/mtbkapp/kapp-vim)
1.  The [`NESASM`](https://github.com/camsaul/nesasm) assembler, built from 
source.
1.  Gimp for making graphics. Although I think I'll be just using white and 
black for the initial version.
1.  [YY-CHR](http://www.romhacking.net/utilities/119/) Another graphics tool that
only runs on Windows as far as I can tell, thus Wine was also installed.
1.  The FCEUX emulator (default version from `apt`) 


This took over 20 miniutes to setup but most of that was downloading Ubuntu Mate
and installing it--so mostly waiting. The rest was pretty easy to install. Next
I'm going to start the [Nerdy Nights Tutorials](http://nintendoage.com/auth/forum/messageview.cfm?catid=22&threadid=7155).
