function [sphandle, spCliHandle,numAdcSamples, numAdcSamples_t, numChirps, sampleRate, freqSlopeConst] = bootup()
    clear all;clc;close all;
% 可更改参数
cfgFileName = 'profile2.cfg';
comportStandardNum = 5;%USB端口号
comportEnhancedNum = 4;%USB端口号

comportUserNum = comportStandardNum;
comportDataNum = comportEnhancedNum;
loadCfg = 1;%上电后或者改变波形参数后第一次采集数据置为1

%debug
global cc;
cc = 1;


%% receiving data

numChirps = 0;

global bytevec;
bytevec = [];
global numSamples_perRx_perChirp;
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

%% bootup main part

tStart = tic;

    while 1
        fprintf(spCliHandle, ''); 
        temp=fread(spCliHandle,100);
        disp('hello i connect');
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
                    fprintf(spCliHandle,cliCmd);
                    fprintf('%s\n',cliCmd);
                end 
            else
                fprintf(spCliHandle,cliCmd);
                fprintf('%s\n',cliCmd);
            end
            radarReply = fscanf(spCliHandle);
            disp(radarReply);
        end
    end
%%
end

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
    %debug
    global cc
    disp(['new read', num2str(cc)])
    cc = cc+1;
    %endofdebug
    bytevec = [bytevec,tempvec];
    readBufferTime = datetime;
    readDataFlag = 1;
end