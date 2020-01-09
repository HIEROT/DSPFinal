function point_plane = get_point_plane(rx1,rx2,rx3,rx4,numAdcSamples,...
    sampleRate,freqSlopeConst,numChirps)
% clc;clear all;close all;
% load data2p.mat

% input1: rxData - [numAdcSamples,numChirps]

sampleRate = sampleRate*1000; % kbps->bps
freqSlopeConst = freqSlopeConst*1e12; % MHz/us->Hz/s
lightSpeed_meters_per_sec = 3e8;
lambda = 3.9*1e-3;
cnt = 256*32;
len = lambda/2;
para = (((1/numAdcSamples)*sampleRate)/freqSlopeConst)*lightSpeed_meters_per_sec/2;

x1 = reshape(rx1,1,[]);
x2 = reshape(rx2,1,[]);
x3 = reshape(rx3,1,[]);
x4 = reshape(rx4,1,[]);
X = [x1;x2;x3;x4];
R = zeros(4,4);
for i = 1 : cnt
    R = R + X(:,i)*X(:,i)'/cnt;
end
w = zeros(4,181);
p = zeros(1,181);
for i = -90 : 90
    theta = i/180*pi;
    del = 2*pi*len*sin(theta)/lambda;
    a = [1, exp(1j*del), exp(2j*del), exp(3j*del)];
    p(i+91) = abs(1/(a*inv(R)*a'));
    w(:,i+91) = inv(R)*a'/(a*inv(R)*a');
end
[~,target_theta] = findpeaks(p);
cnt_target = length(target_theta);
y = zeros(1,181);
for i = 1 : cnt_target
    tmp = w(:,target_theta(i))'*X;
    F = abs(fft(tmp,cnt));
    figure;
    plot(F);
    [~,pos] = max(F(1:cnt/2));
    y(i) = pos*para/32;
end
z = zeros(cnt_target,2);
target_theta = target_theta - 90;
for i = 1 : cnt_target
    z(i,1) = sin(target_theta(i)/180*pi)*y(i);
    z(i,2) = cos(target_theta(i)/180*pi)*y(i);
end
figure;
plot(p);
figure;
scatter(z(:,1),z(:,2),20);
xlim([-3 3]);
ylim([0 5]);

% Range FFT (1D-FFT)
% rangeFFT = fft(rxData,numAdcSamples);
% hanningWin = hanning(numAdcSamples); % numRangeBins = numAdcSamples
% hanningWin = repmat(hanningWin,1,numChirps);
% rangeFFT1 = fft(rx1.*hanningWin,numAdcSamples);%对每一列进行fft（加了窗）

% Doppler FFT (2D-FFT)
%RD_plane = fft(rangeFFT,numChirps,2);%对每一行进行fft

% plot
% tmp = fftshift(abs(RD_plane),2);
% imagesc(1:numChirps,x_axis,tmp);
% xlabel('doppler'); ylabel('range'); title('2D FFT');
% end
