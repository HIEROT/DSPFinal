function out=sound1(input)
L = size(input,2);
fs = 44100; % sample rate
dt = 1/fs;

T16 = 0.125;
t16 = [0:dt:T16];
k = size(t16,2);
t = linspace(0,8*T16,8*k);
i = size(t,2);

mod = sin(pi*t/t(end));

f0 = 261.63; 

ScaleTable = [1 2^(1/6) 2^(1/3) 2^(5/12) 2^(7/12) 2^(9/12) 2^(11/12) 2];

for i=1:L
    if input(i)~=0
        s = mod.*cos(2*pi*ScaleTable(input(i))*f0*t);
        sound(s,fs);
    end
end