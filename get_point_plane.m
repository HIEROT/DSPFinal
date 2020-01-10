function point_plane = get_point_plane(rx1,rx2,rx3,rx4,numAdcSamples,...
   sampleRate,freqSlopeConst,numChirps)
%clc;clear all;close all;
%load data_handblock1.mat
%load data_ceiling.mat

sampleRate = sampleRate*1000; % kbps->bps
freqSlopeConst = freqSlopeConst*1e12; % MHz/us->Hz/s
lightSpeed_meters_per_sec = 3e8;
lambda = 3.9*1e-3;
cnt = 256*32;
len = lambda/2;
para = (((1/numAdcSamples)*sampleRate)/freqSlopeConst)*lightSpeed_meters_per_sec/2/32;
x_dis = (0:cnt-1)*para;

distanc_res = floor(1.5/para);

x1 = reshape(rx1,1,[]);
x2 = reshape(rx2,1,[]);
x3 = reshape(rx3,1,[]);
x4 = reshape(rx4,1,[]);
X = [x1;x2;x3;x4];
J = [0,0,0,1;
     0,0,1,0;
     0,1,0,0;
     1,0,0,0;];
X = [X,J*conj(X)];
R = zeros(4,4);
for i = 1 : 2*cnt
    R = R + X(:,i)*X(:,i)'/cnt/2;
end
R_inv = inv(R);
w = zeros(4,181);
p = zeros(1,181);
for i = -90 : 90
    theta = i/180*pi;
    del = 2*pi*len*sin(theta)/lambda;
    a = [1, exp(1j*del), exp(2j*del), exp(3j*del)];
    p(i+91) = abs(1/(a*R_inv*a'));
    w(:,i+91) =  R_inv*a'/(a*R_inv*a');
end
target_theta = zeros(0,0);
for i = 1 : 181
    target_theta = [target_theta,i];
end
cnt_target = length(target_theta);
y = zeros(1,181);
for i = 1 : cnt_target
    tmp = w(:,target_theta(i))'*X;
    F = abs(fft(tmp,cnt));
    % figure;
    % plot(x_dis,F);
    [~,pos] = max(F(1:min(distanc_res,cnt/2)));
    y(i) = pos*para;
end
z = zeros(1,2);
target_theta = target_theta - 90;
cnt_point = 0;
for i = 1 : cnt_target
    if y(i) < 0.1
        continue;
    end
    cnt_point = cnt_point + 1;
    z(cnt_point,1) = pi/2-target_theta(i)/180*pi;
    z(cnt_point,2) = y(i);
end
figure;
p = p/max(p);
plot(p);
figure;
polarscatter(z(:,1),z(:,2),20);
thetalim([0 180]);
rlim([0 1.5]);
