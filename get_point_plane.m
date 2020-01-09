function point_plane = get_point_plane(rx1,rx2,rx3,rx4,numAdcSamples,...
    sampleRate,freqSlopeConst,numChirps)

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
w = zeros(4,121);
for i = -60 : 60
    theta = i/180*pi;
    del = 2*pi*len*sin(theta)/lambda;
    a = [1, exp(1j*del), exp(2j*del), exp(3j*del)];
    w(:,i+61) = inv(R)*a'/(a*inv(R)*a');
    t = 0;
    for j = 1 : 4
        t = t + abs(w(j,i+61))^2;
    end
    w(:,i+61) = w(:,i+61)/sqrt(t);
end
y = zeros(1,121);
sum = zeros(1,121);
for i = 1 : 121
    tmp = w(:,i)'*X;
    F(:) = abs(fft(tmp,cnt));
    max_tmp = 0;
    max_pos = 0;
    for j = 1 : cnt/2
        if F(j) > max_tmp
            max_tmp = F(j);
            max_pos = j; 
        end
    end
    y(i) = max_pos*para/32;
    sum(i) = max_tmp^2;
end
z = zeros(121,2);
for i = 1 : 121
    z(i,1) = cos((i-61)/180*pi)*y(i);
    z(i,2) = sin((i-61)/180*pi)*y(i);
end
scatter(z(:,1),z(:,2),2,'filled');
xlim([0 2]);
ylim([-1 1]);
point_plane = y;

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
end