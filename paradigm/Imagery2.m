function Imagery2

global hd

hd.numblocks = 5;

nshost = '10.0.0.42';
nsport = 55513;

%connect to netstation only the first time
if ~isfield(hd,'nsConnect') && exist('nshost','var') && exist('nsport','var')
    fprintf('Connecting to NetStation.\n');
    NetStation('Connect',nshost,nsport);
    hd.nsConnect = 1;
end

%setup block number at first run
if ~isfield(hd,'blocknum')
    hd.blocknum = 1;
end

%init psychtoolbox sound
if ~isfield(hd,'pahandle')
    hd.f_sample = 22050;
    fprintf('Initialising audio.\n');
    
    InitializePsychSound
    
    if PsychPortAudio('GetOpenDeviceCount') == 1
        PsychPortAudio('Close',0);
    end
    
    %Mac
    if ismac
        audiodevices = PsychPortAudio('GetDevices');
        outdevice = strcmp('Built-in Output',{audiodevices.DeviceName});
        hd.outdevice = 1;
    elseif ispc
        %DMX
        % audiodevices = PsychPortAudio('GetDevices',3);
        % outdevice = strcmp('DMX 6Fire USB ASIO Driver',{audiodevices.DeviceName});
        % hd.outdevice = 2;
        
        %Windows
        audiodevices = PsychPortAudio('GetDevices',2);
        outdevice = strcmp('Microsoft Sound Mapper - Output',{audiodevices.DeviceName});
        hd.outdevice = 3;
    else
        error('Unsupported OS platform!');
    end
    
    hd.pahandle = PsychPortAudio('Open',audiodevices(outdevice).DeviceIndex,[],[],hd.f_sample,2);
end

while hd.blocknum <= hd.numblocks
    NetStation('Synchronize');
    pause(1);
    NetStation('StartRecording');
    pause(1);
    
    NetStation('Event','BGIN',GetSecs,0.001,'BNUM',hd.blocknum);
    
    fprintf('\nStarting block %d of %d.\n',hd.blocknum,hd.numblocks);
    
    tic
    try2move
    tElapsed = toc;
    fprintf('Block %d took %.1f min.\n',hd.blocknum,tElapsed/60);
    
    NetStation('Event','BEND',GetSecs,0.001,'BNUM',hd.blocknum);
    pause(1);
    NetStation('StopRecording');
    
    hd.blocknum = hd.blocknum+1;

    if pausefor(5)
        break;
    end
end

if hd.blocknum > hd.numblocks
    PsychPortAudio('Close',hd.pahandle);
    clear global hd
    fprintf('DONE!\n');
end

function try2move

global hd

%% load instruction files
fprintf('Preparing task\n');

Mv1Inst = wavread('tryRH.wav');
Mv2Inst = wavread('tryLH.wav');
RestInst = wavread('jstREL.wav');

Mv1Inst = repmat(Mv1Inst',2,1);
Mv2Inst = repmat(Mv2Inst',2,1);
RestInst = repmat(RestInst',2,1);

%% arrange trial order
blocklist = {'Mv1','Mv2','Rst'};
Mov1Count = 12;
Mov2Count = 12;
RestCount = 12;

blockorder = blocklist([ones(1,Mov1Count) ones(1,Mov2Count)+1 ones(1,RestCount)+2]);

%setup quasi-randomized trial order
maxconsec = 2;
while true
    blockorder = blockorder(randperm(length(blockorder)));
    
    %make sure that the first instruction is a movement
    if ~strcmp(blockorder{1},blocklist{1}) && ~strcmp(blockorder{1},blocklist{2})
        continue;
    end
    
    %make sure that the last instruction is a rest
    if ~strcmp(blockorder{end},blocklist{3})
        continue;
    end
    
    %check that no instruction type occurs more than maxconsec times in
    %succession
    b = 1;
    while b <= length(blocklist)
        if ~isempty(strfind(cell2mat(blockorder),repmat(blocklist{b},1,maxconsec+1)))
            break;
        end
        b = b+1;
    end
    if b > length(blocklist)
        break;
    end
end

%% run task

WaitSecs(4); % because of NetStation filtering artifacts

for trialnum = 1:length(blockorder)
    
    fprintf('Trial %d (%s) of %d...\n', trialnum, blockorder{trialnum}, length(blockorder));
    
    switch blockorder{trialnum}
        case 'Mv1'
            PsychPortAudio('FillBuffer',hd.pahandle,Mv1Inst);
            PsychPortAudio('Start',hd.pahandle,1,0,1);

        case 'Mv2'
            PsychPortAudio('FillBuffer',hd.pahandle,Mv2Inst);
            PsychPortAudio('Start',hd.pahandle,1,0,1);

        case 'Rst'
            PsychPortAudio('FillBuffer',hd.pahandle,RestInst);
            PsychPortAudio('Start',hd.pahandle,1,0,1);
            
    end
    
    NetStation('Event',blockorder{trialnum},GetSecs,0.001,'BNUM',hd.blocknum,'TNUM',trialnum);
    
    %Wait for audio to finish playing
    PsychPortAudio('Stop',hd.pahandle,1);
    
    WaitSecs(7-3*rand(1));
    
end
