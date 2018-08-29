---
title: "A bit of 6502 Assembly"
date: 2018-08-23T14:19:31-04:00
draft: false 
tags: ["NES"]
---


For some time I've been thinking about how fun it would be to build a copy of an
old Moon Landing game. I recently discovered that there are tools for writing
NES roms from 6502 assembly, C, and JavaScript. I've got an emulator running on a 
Raspberry Pi 2 with a SNES controller. I think it would be super fun to build and 
play a homemade game on it. 

To that end I've gone through 
[Nick Morgan's Easy 6502 Tutorial](https://skilldrick.github.io/easy6502/) and 
it was a lot of fun. For me, the Snake Game took quite a bit to grok. 
Programming in assembly code, to me at least, is very different than using high
level languages. 

One extra exercise I did was to write a program to print all the colors 
available in the Easy 6502 Simulator. The screen is 32x32 pixels and there are
16 colors. I wanted to print 2 colors per line to fill the whole screen. Below 
is what I came up with. I embeded Nick Morgan's Easy 6502 Simulator.It's 
probably not the greatest but it works. I'm not sure why the carry bit is set 
on branching instructions but I need to clear it after each branch or weird 
things happens with `adc` and probably other instructions I don't understand 
well.

If I can I'd like to work on this Moon Lander game for 20 minutes a day and 
document the adventure here.

<div id="easy6502sim">
  <style>
    .widget {
      width: 600px;
      margin: 30px auto;
      font-size: 12px;
      line-height: 1.5;
    }

    .buttons {
      margin: 8px 0;
    }

    .start, .length {
      width: 50px;
    }

    .widget pre {
      margin: 0;
      padding: 0;
      background: inherit;
      border: none;
    }

    .code {
      margin: 0 0 6px 0;
      padding: 6px;
      border: 1px solid black;
      width: 420px;
      height: 290px;
      font-family: monospace;
      overflow: auto;
      float: left;
    }

    .screen {
      float: right;
    }

    .debugger {
      border: 1px black solid;
      margin-top: 6px;
      padding: 3px;
      padding-top: 8px;
      height: 125px;
      width: 152px;
      text-align: center;
      float: right;
    }

    .minidebugger {
      margin: 0;
      margin-top: 6px;
      padding: 0;
      font-family: monospace;
      font-size: 11px;
    }

    .monitorControls {
      width: 587px;
      clear: both;
      margin-bottom: 10px;
      padding: 0;
    }

    .monitorControls input {
      margin-right: 0.5em;
    }

    .monitor {
      margin: 10px 0;
      padding: 6px;
      border: 1px solid #999;
      background-color: #ddd;
      width: 587px;
      height: 100px;
      overflow: auto;
      display: none;
    }

    .messages {
      margin: 0;
      padding: 6px;
      border: 1px solid #999;
      background-color: #eee;
      overflow: auto;
      width: 587px;
      height: 100px;
      text-align: left;
      font-size: 12px;
      color: #444;
    }
  </style>

  <div class="widget">
  <div class="buttons">
  <input type="button" value="Assemble" class="assembleButton" />
  <input type="button" value="Run" class="runButton" />
  <input type="button" value="Reset" class="resetButton" />
  <input type="button" value="Hexdump" class="hexdumpButton" />
  <input type="button" value="Disassemble" class="disassembleButton" />
  <input type="button" value="Notes" class="notesButton" />
  </div>
  <pre style="display: inline; margin: 0; border: 0; padding: 0;">
  <textarea class="code">
define rowL $00
define rowH $01
define screenL $00
define screenH $02
define width $20
define colors $10

jsr init
jsr allColors
jmp end

init:
  lda #screenL
  sta rowL
  lda #screenH
  sta rowH
  rts

; draws 2 lines on the screen for each color starting at the top and filling whole screen
allColors:
  ldx #$00 ; X holds the current color
allColorsLoop:
  txa
  jsr drawLine
  jsr nextRow
  txa
  jsr drawLine
  jsr nextRow
  inx
  cpx #colors
  bne allColorsLoop
  clc
  rts

; draws the color in A in a line of color width long on the screen starting at rowL/rowH
drawLine:
  ldy #$00 ; the offset in bytes to the rowL/rowH
drawLineLoop:
  sta (rowL), Y
  iny
  cpy #width
  bne drawLineLoop
  clc
  rts

; increments the screen address at rowL/rowH down to the next row
nextRow:
  lda #width
  adc rowL
  sta rowL
  bcs carry
  rts
carry:
  clc ; weird things happen if the carry bit isn't cleared after branching
  inc rowH
  rts

end:
  </textarea>
  </pre>

   <canvas class="screen" width="160" height="160"></canvas>

  <div class="debugger">
  <input type="checkbox" class="debug" name="debug" />
  <label for="debug">Debugger</label>
  <div class="minidebugger"></div>
  <div class="buttons">
  <input type="button" value="Step" class="stepButton" />
  <input type="button" value="Jump to ..." class="gotoButton" />
  </div>
  </div>

  <div class="monitorControls">
  <label for="monitoring">Monitor</label>
  <input type="checkbox" class="monitoring" name="monitoring" />

  <label for="start">Start: $</label>
  <input type="text" value="0" class="start" name="start" />
  <label for="length">Length: $</label>
  <input type="text" value="ff" class="length" name="length" />
  </div>
  <div class="monitor"><pre><code></code></pre></div>
  <div class="messages"><pre><code></code></pre></div>

  <div class="notes" style="display: none">Notes:
Memory location $fe contains a new random byte on every instruction.
Memory location $ff contains the ascii code of the last key pressed.

Memory locations $200 to $5ff map to the screen pixels. Different values will
draw different colour pixels. The colours are:

$0: Black
$1: White
$2: Red
$3: Cyan
$4: Purple
$5: Green
$6: Blue
$7: Yellow
$8: Orange
$9: Brown
$a: Light red
$b: Dark grey
$c: Grey
$d: Light green
$e: Light blue
$f: Light grey
  </div>
  <script src="../es5-shim.js"></script>
  <script src="https://ajax.googleapis.com/ajax/libs/jquery/1.7.2/jquery.min.js"></script>
  <script src="../easy6502.js"></script>
</div>
