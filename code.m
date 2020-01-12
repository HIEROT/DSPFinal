%% main function

function code(sphandle, spCliHandle,numAdcSamples, numAdcSamples_t, numChirps, sampleRate, freqSlopeConst)

global bytevec;
bytevec = [];
% global numSamples_perRx_perChirp;
global readBufferTime;
global readDataFlag;
readDataFlag = 0;

cnt = 120;
k_last = 0;

while(cnt > 0)
    tic
    cnt = cnt - 1

    fprintf(spCliHandle,'sensorStop');
    radarReply = fscanf(spCliHandle);
    pause(0);
    readBufferTime = datetime;
    bytevec = [];
    fprintf(spCliHandle,'sensorStart');
    fprintf('%s\n','sensorStart');
    radarReply = fscanf(spCliHandle);
%     disp(radarReply);

%% debug
%     numChirps = 8;
%%

while 1
    if size(bytevec,2) >= numChirps*4
        bytevec1 = bytevec;
        break
    end
%     if readDataFlag == 0
%         if diff([readBufferTime,datetime]) > duration([0,0,10])
%             disp('7777发送的参数有问题，请重新配置参数并重启雷达！');
%             if ~isempty(instrfind('Type','serial'))
%                 fclose(instrfind('Type','serial'));
%                 delete(instrfind('Type','serial'));  % delete open serial ports.
%             end
%             return
%         end
%     else
        if diff([readBufferTime,datetime]) > duration([0,0,10])
            disp('8888发生丢包，请重新采集数据！');
            fprintf(spCliHandle,'sensorStop');
            if ~isempty(instrfind('Type','1serial'))
                fclose(instrfind('Type','serial'));
                delete(instrfind('Type','serial'));  % delete open serial ports.
            end
            return
        end        
%     end
end

fprintf(spCliHandle,'sensorStop');
disp('sensorStop');

bytevec1 = bytevec;
bytevec1 = reshape(bytevec1,1,[]);
bytevec1 = uint8(bytevec1);
tmp = typecast(bytevec1,'int16');
% bytevec = bytevec;
% bytevec = reshape(bytevec,1,[]);
% bytevec = uint8(bytevec);
% tmp = typecast(bytevec,'int16');
tmp = double(reshape(tmp,2,[]));
tmp = tmp(1,:)+1i*tmp(2,:);
tmp = reshape(tmp,numAdcSamples_t,[]);
rx1 = tmp(:,1:4:numChirps*4);
rx2 = tmp(:,2:4:numChirps*4);
rx3 = tmp(:,3:4:numChirps*4);
rx4 = tmp(:,4:4:numChirps*4);
rx1 = rx1(1:numAdcSamples,:);
rx2 = rx2(1:numAdcSamples,:);
rx3 = rx3(1:numAdcSamples,:);
rx4 = rx4(1:numAdcSamples,:);
rx1 = reshape(rx1,1,[]);
rx2 = reshape(rx2,1,[]);
rx3 = reshape(rx3,1,[]);
rx4 = reshape(rx4,1,[]);
adcData = [rx1;rx2;rx3;rx4];

%%

% rx1~4 表示四根接收天线的接收信号
% rx1为一个矩阵，每一列表示一帧chirp回波，列数代表帧数
% 基本信号处理例程
rx1 = reshape(adcData(1,:),numAdcSamples,[]);
rx2 = reshape(adcData(2,:),numAdcSamples,[]);
rx3 = reshape(adcData(3,:),numAdcSamples,[]);
rx4 = reshape(adcData(4,:),numAdcSamples,[]);

% distance & angle calculation unit
z = get_point_plane(rx1,rx2,rx3,rx4,numAdcSamples,sampleRate,freqSlopeConst,numChirps);

% quantitization unit
[z_ref,k] = pos2ind(z)
polarscatter([z_ref(:,1)],[z_ref(:,2)],10);
thetalim([0 180]);
rlim([0 2]);

% sound producing unit
sound2(k,k_last)
k_last = k;

toc

end

%% close ports
% 释放串口
if ~isempty(instrfind('Type','serial'))
    fclose(instrfind('Type','serial'));
    delete(instrfind('Type','serial'));  % delete open serial ports.
end

end

%%
