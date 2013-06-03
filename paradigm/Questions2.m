function Questions2

global hd

hd.numblocks = 3;

nshost = '10.0.0.42';
nsport = 55513;

%connect to netstation only the first time
if ~isfield(hd,'nsConnect') && exist('nshost','var') && exist('nsport','var')
    fprintf('Connecting to NetStation.\n');
    NetStation('Connect',nshost,nsport);
    hd.nsConnect = 1;
end

hd.blocknum = 1;

%init psychtoolbox sound
if ~isfield(hd,'pahandle')
    hd.f_sample = 22050;
    fprintf('Initialising audio.\n');
    
    InitializePsychSound
    
    if PsychPortAudio('GetOpenDeviceCount') == 1
        PsychPortAudio('Close',0);
    end
    
    %Try Terratec DMX ASIO driver first. If not found, revert to
    %native sound device
    if ispc
        audiodevices = PsychPortAudio('GetDevices',3);
        if ~isempty(audiodevices)
            %DMX audio
            outdevice = strcmp('DMX 6Fire USB ASIO Driver',{audiodevices.DeviceName});
            hd.outdevice = 2;
        else
            %Windows default audio
            audiodevices = PsychPortAudio('GetDevices',2);
            outdevice = strcmp('Microsoft Sound Mapper - Output',{audiodevices.DeviceName});
            hd.outdevice = 3;
        end
    elseif ismac
        audiodevices = PsychPortAudio('GetDevices');
        %DMX audio
        outdevice = strcmp('TerraTec DMX 6Fire USB',{audiodevices.DeviceName});
        hd.outdevice = 2;
        if sum(outdevice) ~= 1
            %Mac default audio
            audiodevices = PsychPortAudio('GetDevices');
            outdevice = strcmp('Built-in Output',{audiodevices.DeviceName});
            hd.outdevice = 1;
        end
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
    askquestions
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

function askquestions

global hd

%% load instruction files
fprintf('Preparing task\n');

audiolist = {
    'CorrectName'
    'IncorrectName'
    'Sky'
    'Banana'
    'Elephant'
    'Pain'
    'Yes'
    'No'
    'Blue'
    'Yellow'
    };

for a = 1:length(audiolist)
    wav.(audiolist{a}) = repmat(wavread(sprintf('%s.wav',audiolist{a}))',2,1);
end

blockorder = {
    'CorrectName',  'QUE1', 2
    'Yes',          'ANS1', 4
    'No',           'ANS2', 4
    'IncorrectName','QUE2', 2
    'Yes',          'ANS1', 4
    'No',           'ANS2', 4
    'Sky',          'QUE3', 2
    'Blue',         'ANS1', 4
    'Yellow',       'ANS2', 4
    'Banana',       'QUE4', 2
    'Blue',         'ANS1', 4
    'Yellow',       'ANS2', 4
    'Elephant',     'QUE5', 2
    'Yes',          'ANS1', 4
    'No',           'ANS2', 4
    'Pain',         'QUE6', 2
    'Yes',          'ANS1', 4
    'No',           'ANS2', 4
    };

%% run task

WaitSecs(4); % because of NetStation filtering artifacts

for trialnum = 1:size(blockorder,1)
    
    fprintf('Instruction %d (%s) of %d...\n', trialnum, blockorder{trialnum,1}, length(blockorder));
    
    PsychPortAudio('FillBuffer',hd.pahandle,wav.(blockorder{trialnum,1}));
    PsychPortAudio('Start',hd.pahandle,1,0,1);
    NetStation('Event',blockorder{trialnum,2},GetSecs,0.001,'BNUM',hd.blocknum,'TNUM',trialnum);
    PsychPortAudio('Stop',hd.pahandle,3);
    WaitSecs(blockorder{trialnum,3});
end

WaitSecs(4); % because of NetStation filtering artifacts

