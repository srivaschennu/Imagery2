function motorprep_import(basename)

loadpathsPREP;
global eegdata;

%% load raw data

load([filepath basename '-1.mat']);
data1 = y(:,1:end-1);
load([filepath basename '-2.mat']);
data2 = y(:,1:end-1);
load([filepath basename '-3.mat']);
data3 = y(:,1:end-1);
load([filepath basename '-4.mat']);
data4 = y(:,1:end-1);
load([filepath basename '-5.mat']);
data5 = y(:,1:end-1);
% load([filepath basename '-6.mat']);
% data6 = y(:,1:end-1);

%% merge data
data = cat(2,data1,data2,data3,data4);%,data5,data6);

%% remove timing channel
data = data(2:end,:);
eegdata = data;

%% create EMG channels
EMG1 = data(end,:) - data(end-1,:);
EMG2 = data(end-2,:) - data(end-3,:);
% 
% %% filter EMG
% EMG1 = eegfilt(EMG1,256,30,[]);
% EMG2 = eegfilt(EMG2,256,30,[]);
% 
% EMG1 = EMG1 .^ 2;
% EMG2 = EMG2 .^ 2;
% 
%% put into variable for eeglab
eegdata = cat(1,data(1:end-4,:),EMG1,EMG2);

%% put it into workspace
evalin('base','global eegdata');

%% put into EEGLAB
EEG = pop_importdata('dataformat','array','nbchan',8,'data','eegdata','srate',256,'pnts',0,'xmin',0);

%% import events from channel one
EEG = pop_chanevent(EEG, 1,'edge','leading','edgelen',0);

%% filter
lopass = 40;
EEG = pop_eegfilt( EEG, [], lopass, [], [0], [0]); % doesn't use FFT filter option

%% add channel info
EEG = pop_chanedit(EEG, 'load',{'/Users/dcruse/Home Space/Motor Preparation/9elecs.locs' 'filetype' 'autodetect'});

%% rename the events
for i = 1:length(EEG.event)
    if EEG.event(i).type == 1
        EEG.event(i).type = 'Mov1';
    elseif EEG.event(i).type == 2
        EEG.event(i).type = 'Mov2';
    elseif EEG.event(i).type == 3
        EEG.event(i).type = 'Rest';
    end
end

%% epoch around events
EEG = pop_epoch( EEG, {  }, [0 6], 'epochinfo', 'yes');

%% save it
EEG.filepath = filepath;
EEG.setname = sprintf('%s_raw',basename);
EEG.filename = sprintf('%s_raw.set',basename);

fprintf('Saving %s%s.\n', EEG.filepath, EEG.filename);
pop_saveset(EEG,'filename', EEG.filename, 'filepath', EEG.filepath);

