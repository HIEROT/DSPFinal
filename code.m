%% main function

function code()

clear all;clc;close all;
% 可更改参数
cfgFileName = 'profile2.cfg';
comportStandardNum = 5;%USB端口号
comportEnhancedNum = 4;%USB端口号

comportUserNum = comportStandardNum;
comportDataNum = comportEnhancedNum;
loadCfg = 1;%上电后或者改变波形参数后第一次采集数据置为1
% 重复计算
cnt = 120;
arr = [];

% [readBufferTime,numAdcSamples,sampleRate,freqSlopeConst,numChirps] = ...
%     getRawData(cfgFileName,comportStandardNum,comportEnhancedNum,loadCfg);

% 获取的数据存储在adcData中
% adcData = receive_data(numChirps,readBufferTime);
% [adcData,numAdcSamples,sampleRate,freqSlopeConst,numChirps] = ...
%     GetRawData(cfgFileName,comportStandardNum,comportEnhancedNum,loadCfg);

%% receiving data

adcData = [];
numChirps = 0;

global bytevec;
bytevec = [];
global numSamples_perRx_perChirp;
global readBufferTime;
global readDataFlag;
readDataFlag = 0;

cfgFileId = fopen(cfgFileName,'r');
if cfgFileId == -1
    fprintf('File %s not found!\n',cfgFileName);
    return
elseif loadCfg == 1
    fprintf('Opening configuration file %s ...\n',cfgFileName);
end
cliCfg = [];
tline = fgetl(cfgFileId);
k = 1;
while ischar(tline)
    cliCfg{k} = tline;
    tline = fgetl(cfgFileId);
    k = k+1;
end
fclose(cfgFileId);

% read numAdcSamples from 'profileCfg' 
for k = 1:length(cliCfg)
    cliCmd = cliCfg{k};
    if(cliCmd(1)~='%')
        if(length(cliCmd)>=10)
            if(sum(cliCmd(1:8)=='frameCfg')==8)
                cliCmd_split = strsplit(cliCmd,' ');
                numChirps = str2double(cliCmd_split{1,4});
            elseif(sum(cliCmd(1:10)=='profileCfg')==10)
                cliCmd_split = strsplit(cliCmd,' ');
                sampleRate = str2double(cliCmd_split{1,12});
                freqSlopeConst = str2double(cliCmd_split{1,9});
                numAdcSamples = str2double(cliCmd_split{1,11});
                if(numAdcSamples>1024)
                    disp('6666参数有问题，请降低距离分辨率或减小最大不模糊距离！');
                    return
                end
                numAdcSamples_t = power(2,ceil(log2(numAdcSamples)));
                numSamples_perRx_perChirp = numAdcSamples_t * 2 * 2;
            end
        end
    end
end

% Configure data UART port
sphandle = configureSport(comportDataNum);

% Send Configuration Parameters to Board
% Open CLI port
spCliHandle = configureCliPort(comportUserNum);

warning off; % MATLAB: serial:fread:unsuccessfulRead
timeOut = get(spCliHandle,'Timeout');
set(spCliHandle,'Timeout',1);

while(cnt > 0)
tic
cnt = cnt - 1

if loadCfg == 1
    tStart = tic;

    while 1
        fprintf(spCliHandle, ''); 
        temp=fread(spCliHandle,100);
        disp('hello i read');
        temp = strrep(strrep(temp,char(10),''),char(13),''); %#ok<*CHARTEN>
        if ~isempty(temp)
                break;
        end
        pause(0.1);
        toc(tStart);
    end
    set(spCliHandle,'Timeout', timeOut);
    warning on;

    % Send CLI configuration to board
    fprintf('Sending configuration to board %s ...\n',cfgFileName);
    for k=1:length(cliCfg)
        cliCmd = cliCfg{k};
        if(cliCmd(1)~='%')
            if length(cliCmd)>=11
                if(sum(cliCmd(1:8)=='frameCfg')==8)
                    cliCmd_split = strsplit(cliCmd,' ');
                    numChirps = str2double(cliCmd_split{1,4});
                    framePeriod = str2double(cliCmd_split{1,6});
                    frameCfgCmd = ['frameCfg ',num2str(0),' ',num2str(0),' '...
                        ,num2str(numChirps),' ',num2str(1),' ',num2str(framePeriod),...
                        ' ',num2str(1),' ',num2str(0)];
                    fprintf(spCliHandle,frameCfgCmd);
                    fprintf('%s\n',frameCfgCmd);
                else
                    if(sum(cliCmd(1:11)=='sensorStart')==11)
                        readBufferTime = datetime;
                    end
                    fprintf(spCliHandle,cliCmd);
                    fprintf('%s\n',cliCmd);
                end 
            else
                fprintf(spCliHandle,cliCmd);
                fprintf('%s\n',cliCmd);
            end
            radarReply = fscanf(spCliHandle);
            disp(radarReply);
            pause(0);
        end
    end
else
    fprintf(spCliHandle,'sensorStop');
    radarReply = fscanf(spCliHandle);
    pause(0);
    readBufferTime = datetime;
    fprintf(spCliHandle,'sensorStart');
    fprintf('%s\n','sensorStart');
    radarReply = fscanf(spCliHandle);
    disp(radarReply);
end

%% debug
% numChirps = 10;
%%

while 1
    if size(bytevec,2) >= numChirps*4
%         set(sphandle,'BytesAvailableFcn',@readNothing);
    bytevec1 = bytevec;
        break
    end
    if readDataFlag == 0
        if diff([readBufferTime,datetime]) > duration([0,0,10])
            disp('7777发送的参数有问题，请重新配置参数并重启雷达！');
            if ~isempty(instrfind('Type','serial'))
                fclose(instrfind('Type','serial'));
                delete(instrfind('Type','serial'));  % delete open serial ports.
            end
            return
        end
    else
        if diff([readBufferTime,datetime]) > duration([0,0,10])
            disp('8888发生丢包，请重新采集数据！');
            fprintf(spCliHandle,'sensorStop');
            if ~isempty(instrfind('Type','1serial'))
                fclose(instrfind('Type','serial'));
                delete(instrfind('Type','serial'));  % delete open serial ports.
            end
            return
        end        
    end
end

fprintf(spCliHandle,'sensorStop');

disp('out of while')
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
bytevec = [];
%%

loadCfg = 0;
% rx1~4 表示四根接收天线的接收信号
% rx1为一个矩阵，每一列表示一帧chirp回波，列数代表帧数
% 基本信号处理例程
rx1 = reshape(adcData(1,:),numAdcSamples,[]);
rx2 = reshape(adcData(2,:),numAdcSamples,[]);
rx3 = reshape(adcData(3,:),numAdcSamples,[]);
rx4 = reshape(adcData(4,:),numAdcSamples,[]);

% 对接收信号直接fft，可获取静止目标的距离信息
% fft后的序列索引与实际距离的对应关系需要换算
%rangeFFT1 = fft(rx1,numAdcSamples);% 对每一列进行fft
%figure; 
%tmp = abs(rangeFFT1);
%plot(abs(rangeFFT1));
%xlabel('FFT index')
%ylabel('Amplitude')

% 对接收的信号数据矩阵，进行2维fft，获取距离-速度平面
% 峰值对应了目标的距离和 速度

z = get_point_plane(rx1,rx2,rx3,rx4,numAdcSamples,sampleRate,freqSlopeConst,numChirps);
z_ref = pos2ind(z)
polarscatter([z_ref(:,1)],[z_ref(:,2)],10);
thetalim([0 180]);
rlim([0 2]);

% arr = [arr;z];
% polarscatter(arr(:,1),arr(:,2),5)
% save('z_-21.mat','arr');
toc
% get_dist(rx1,rx2,rx3,rx4,adcData,numAdcSamples);


% save(['./data/',num2str(cnt),'.mat'],'rx1','rx2','rx3','rx4','numAdcSamples','sampleRate','freqSlopeConst','numChirps');
% saveas(gcf,['data/',num2str(cnt),'.jpg']);
end

%% close ports
% 释放串口
if ~isempty(instrfind('Type','serial'))
    fclose(instrfind('Type','serial'));
    delete(instrfind('Type','serial'));  % delete open serial ports.
end

end

%%

function [sphandle] = configureSport(comportSnum)
    global numSamples_perRx_perChirp;
    % 释放被占用的串口
    if ~isempty(instrfind('Type','serial'))
        disp('Serial port(s) already open. Re-initializing...');
        fclose(instrfind('Type','serial'));
        delete(instrfind('Type','serial'));  % delete open serial ports.
    end
    comportnum_str=['COM' num2str(comportSnum)];
    sphandle = serial(comportnum_str,'BaudRate',921600);
    set(sphandle,'InputBufferSize',numSamples_perRx_perChirp);
    set(sphandle,'Timeout',10);
    set(sphandle,'ErrorFcn',@dispError);
    set(sphandle,'BytesAvailableFcnMode','byte');
    set(sphandle,'BytesAvailableFcnCount',numSamples_perRx_perChirp);
    set(sphandle,'BytesAvailableFcn',@readData);
    fopen(sphandle);
end

function [sphandle] = configureCliPort(comportPnum)
%     if ~isempty(instrfind('Type','serial'))
%         disp('Serial port(s) already open. Re-initializing...');
%         delete(instrfind('Type','serial'));  % delete open serial ports.
%     end
    comportnum_str=['COM' num2str(comportPnum)];
    sphandle = serial(comportnum_str,'BaudRate',115200);
    set(sphandle,'ErrorFcn',@dispError);
    set(sphandle,'Parity','none');    
    set(sphandle,'Terminator','CR/LF');
    fopen(sphandle);
end

function [] = dispError()
    disp('Serial port error!');
end

function [] = readData(obj,event) %#ok<*INUSD>
    global bytevec;
    global numSamples_perRx_perChirp;
    global readBufferTime;
    global readDataFlag;
    [tempvec,~] = fread(obj,numSamples_perRx_perChirp,'uint8');
    
    bytevec = [bytevec,tempvec];
    readBufferTime = datetime;
    readDataFlag = 1;
end


function [] = readNothing(obj,event)

end