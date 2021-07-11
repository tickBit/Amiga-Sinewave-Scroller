# Amiga-Sinewave-Scroller

It's been a long time since my active Amiga days, so.. forgive.. :-)

The code could be optimized a lot.

Anyway, in the hidden CHIP mem area there's a blitter scroll, from where the sinewave effect is made with the 68040's CPU and its FPU.

For clearing the screen the code uses 68040's move16 instruction. NOTICE! move16 instruction is not safe for the chip ram, I should use for example movem and/or move to clear the screen with 68040 CPU. Should update the code soon..

I noticed something I've forgotten: So that one doesn't get any "phantom graphics flickering" on the screen, the sprites must be explicitly set off (DMACON), if they're not used.

Short GIF animation of the app:

![Amiga-Sine-Scroller](https://user-images.githubusercontent.com/61118857/117585921-d889a780-b11d-11eb-892e-42480cc2e53f.gif)

Short GIF animation of the 4 bitplanes version:

![Amiga-Sine-Scroller-4bpls](https://user-images.githubusercontent.com/61118857/119268664-9b80e300-bbfc-11eb-8748-d6cfc170c7a7.gif)

