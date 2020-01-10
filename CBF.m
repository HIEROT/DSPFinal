function point_plane = get_point_plane(rx1,rx2,rx3,rx4,numAdcSamples,...
   sampleRate,freqSlopeConst,numChirps)
% clc;clear all;close all;
% load data_theta15deg_handblock.mat
% load data_ceiling.mat

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%para:
plot_figure = 1;
get_avr = 0;
scan_deg = 0;
res_deg = 5;
maxd = 1;
chirp_num = 32;
cnt = 256*32;
gain_para = 80;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
sampleRate = sampleRate*1000; % kbps->bps
freqSlopeConst = freqSlopeConst*1e12; % MHz/us->Hz/s
lightSpeed_meters_per_sec = 3e8;
lambda = 3.9*1e-3;

len = lambda/2;
para = (((1/numAdcSamples)*sampleRate)/freqSlopeConst)*lightSpeed_meters_per_sec/2/chirp_num;
x_dis = (0:cnt-1)*para;

distanc_res = floor(maxd/para);
gain = zeros(1,181);
for i = 1 : 181
    gain(i) = 10^(15/90*abs(i-91)/gain_para);
end
figure;
plot(gain);

x1 = reshape(rx1,1,[]);
x2 = reshape(rx2,1,[]);
x3 = reshape(rx3,1,[]);
x4 = reshape(rx4,1,[]);
X = [x1;x2;x3;x4];
R = X*X'/cnt;
R_inv = inv(R);
w = zeros(4,181);
y = zeros(1,cnt);
for i = -90 : 90 
    theta = i/180*pi;
    del = 2*pi*len*sin(theta)/lambda;
    w(:,i+91) = [1, exp(-1j*del), exp(-2j*del), exp(-3j*del)];
    a = [1, exp(1j*del), exp(2j*del), exp(3j*del)];
    p(i+91) = abs((a*R*a'))*gain(i+91);
end
[~,target_theta] = findpeaks(p);
if scan_deg ~= 0
    target_theta = zeros(1,scan_deg*2+1);
    for i = 1 : 2*scan_deg+1
        target_theta(i) = i+89-scan_deg;
    end
else
    tmp = zeros(0,0);
    for i = 1 : length(target_theta)
        for j = -res_deg : res_deg
            tmp = [tmp,target_theta(i)+j];
        end
    end
    target_theta = tmp;
end
target_theta = target_theta - 90;
cnt_target = length(target_theta);
y = zeros(1,181);
b = zeros(1,181);
for i = 1 : cnt_target
    tmp = w(:,target_theta(i)+91)'*X;
    F = abs(fft(tmp,cnt));
    % figure;
    % plot(x_dis,F);
    [~,pos] = max(F(1:min(distanc_res,cnt/2)));
    y(i) = pos*para;
end
z = zeros(1,2);
cnt_point = 0;
for i = 1 : cnt_target
    if y(i) < 0.1
        continue;
    end
    cnt_point = cnt_point + 1;
    if get_avr == 1
        z(1,1) = z(1,1) + pi/2-target_theta(i)/180*pi;
        z(1,2) = z(1,2) + y(i);
    else
        z(cnt_point,1) = pi/2-target_theta(i)/180*pi;
        z(cnt_point,2) = y(i);
    end
end
if get_avr == 1
    z = z/cnt_point;
end
if plot_figure == 1
    figure;
    p = p/max(p);
    plot(p);
    title('p');
    figure;
    polarscatter(z(:,1),z(:,2),20);
    thetalim([0 180]);
    rlim([0 maxd]);
end
point_plane = z;
