<Cabbage> bounds(0, 0, 0, 0)
form caption("MidiWaves") size(400, 250), guiMode("queue"), pluginId("Mosc"), colour("10,50,100,150")
rslider bounds(112, 6, 72, 61), channel("pitchwidth"), textColour(255, 255, 255, 255) range(0, 30, 5, 1, 1), text("pitchdeviation"),  colour(0, 0, 0, 255)
rslider bounds(206, 6, 72, 61), channel("speed1"), textColour(255, 255, 255, 255) range(0, 10, 1, 0.5, 0.01), text("wavespeed"),  colour(0, 0, 0, 255)

rslider bounds(144, 124, 63, 52), channel("speed2"), textColour(255, 255, 255, 255) range(0.01, 5, 0.1, 0.5, 0.01), text("speed"),  colour(0, 0, 0, 255)
rslider bounds(196, 124, 58, 53), channel("depth"), textColour(255, 255, 255, 255) range(0, 0.1, 0, 0.5, 0.001), text("depth"),  colour(0, 0, 0, 255)
label bounds(22, 202, 369, 17) channel("sine2"), text("sine triangl square  cos  sawup swdwn rnd freeze"), fontColour(255, 255, 255, 255)

rslider bounds(22, 124, 72, 61), channel("duration"), textColour(255, 255, 255, 255) range(0, 3, 0.1, 0.5, 0.01), text("noteduration"),  colour(0, 0, 0, 255)
rslider bounds(82, 124, 72, 61), channel("pause"), textColour(255, 255, 255, 255) range(0, 3, 0.1, 0.5, 0.01), text("pause"),  colour(0, 0, 0, 255)

rslider bounds(264, 124, 72, 61), channel("randveloc"), textColour(255, 255, 255, 255) range(0.05, 1, 0.1, 0.7, 0.01), text("velocity"),  colour(0, 0, 0, 255)

hslider bounds(32, 48, 338, 61), channel("wave1"), textColour(255, 255, 255, 255), range(0, 7, 1, 1, 1) , trackerColour(255, 255, 0, 255)
hslider bounds(32, 166, 338, 61), channel("wave2"), textColour(255, 255, 255, 255), range(0, 7, 1, 1, 1) , trackerColour(255, 255, 0, 255)

label bounds(22, 84, 369, 17) channel("sine1"), text("sine triangl square  cos  sawup swdwn rnd freeze"), fontColour(255, 255, 255, 255)


combobox bounds(332, 126, 60, 30), channel("channels"), colour(0, 0, 0, 255), corners(5), items("1", "1 + 2"), value(1)

</Cabbage>
<CsoundSynthesizer>
<CsOptions>
;-n -d -+rtmidi=NULL -M0 --midi-key-cps=4 --midi-velocity-amp=5
;-dm0 -n --midi-key-cps=4 --midi-velocity-amp=5  -M20 -Q20 -+rtmidi=alsaseq
-dm0 -n -+rtmidi=NULL -M0 -Q0
</CsOptions>
<CsInstruments>
; Initialize the global variables. 
ksmps = 32
nchnls = 2

	opcode k_lfo7,k,kkk
kcps, kdepth, ktype xin
iSineTable	ftgen 	0, 0, 65536, 10, 1 ; sine wave
kout init 0

if (ktype == 0) then                                                            ;SINE
	kout 	oscil3 kdepth, kcps, iSineTable

elseif (ktype == 1) then                                                        ;TRIANGLE
	aout	vco2 kdepth, kcps, 12
	kout downsamp aout

elseif (ktype == 2) then                                                        ;SQUARE (BI-POLAR)
	aout	vco2 kdepth, kcps, 10
	kout downsamp aout

elseif (ktype == 3) then                                                        ;COSINE
	kout 	oscil3 kdepth, kcps, iSineTable, .25

elseif (ktype == 4) then                                                        ;SAW TOOTH (UP)
	aout	vco2 kdepth, kcps, 0
	kout downsamp aout	
        kout = kout * -1

elseif (ktype == 5) then                                                        ;SAW TOOTH (DOWN)
	aout	vco2 kdepth, kcps, 0
	kout downsamp aout

elseif (ktype == 6) then                                                        ;RANDOM
        kout jspline kdepth, kcps, 2                                            ;jitter

elseif (ktype == 7) then                                                        ;FREEZE
        ; empty
endif
xout kout
	endop
	
	
seed 1

instr 1  

inote   notnum        ; use as a start note
ivel 	veloc

krand  chnget "randveloc"

kvel    init  ivel
kres1    random krand, 1         ; vary velocity

kpitch  chnget "pitchwidth"     ; deviation in midi pitch
kdepth  chnget "depth"          ; LFO2 modulation depth of duration & pause
kfreq1   chnget "speed1"        ; speed of LFO1
kfreq2   chnget "speed2"        ; LFO2 speed for mudualting duration & pause
kdur    chnget "duration"       ; length of note
kpause  chnget "pause"          ; length of pause bewteen notes
kwave1   chnget "wave1"         ; LFO wave for pitchwidth
kwave2   chnget "wave2"         ; LFO2 wave for modulating duration & pause
kchan   chnget  "channels"      ; select midi channel 1 or 1 + 2

k1      k_lfo7  kfreq1, kpitch, kwave1 
ktrig   changed2 k1
if ktrig == 1 then
    kvel  =  ivel * kres1
    kvel  = int(kvel)
endif
    
k2      k_lfo7  kfreq2, 1, kwave2 
k2  *=  kdepth

kres2    random krand, 1         ; vary velocity of 2nd midi channel
    kvel2  =  ivel * kres2
    kvel2  = int(kvel2)
    
if (kchan == 1) || (kchan == 0) then    ; choose midi channel 1 or
    moscil  1, inote+int(k1), kvel, k2+kdur, k2+kpause
elseif (kchan == 2) then
    moscil  1, inote+int(k1), kvel, k2+kdur, k2+kpause  ; midichannel 1 + 2
    moscil  2, inote+int(k1), kvel2, k2+kdur, k2+kpause
endif

endin

</CsInstruments>
<CsScore>
;causes Csound to run for about 7000 years...
f0 z
</CsScore>
</CsoundSynthesizer>
