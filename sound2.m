function out=sound2(input,lastinput)
fs = 44100; % sample rate
dt = 1/fs;

T16 = 0.125;
t16 = [0:dt:T16];
k = size(t16,2);
t = linspace(0,100*T16,100*k);

mod = sin(pi*t/t(end));

f0 = 261.63; 

ScaleTable = [1 2^(1/6) 2^(1/3) 2^(5/12) 2^(7/12) 2^(9/12) 2^(11/12) 2 2^(7/6) 2^(4/3)];

if input==0
    clear sound;
elseif input~=lastinput
    clear sound
    s = mod.*cos(2*pi*ScaleTable(input)*f0*t);
    sound(s,fs);
end