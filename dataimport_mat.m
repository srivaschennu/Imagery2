function dataimport(basename)

loadpaths
chanlocfile = 'GSN-HydroCel-129.sfp';

fprintf('Loading %s%s.mat.\n',filepath,basename);
load(sprintf('%s%s.mat',filepath,basename));

%extract sampling rate from first channel
fs = 1/(data(1,2) - data(1,1));

% delete the first channel, which contains the sample time
data = data(2:end,:);

%%% SCALE DATA CHANNELS BY CONSTANT FACTOR
scalefactor = 1/10;
data(1:end-1,:) = data(1:end-1,:) .* scalefactor;

%import data into EEGLAB
fprintf('Importing data into eeglab.\n');
assignin('base','data',data);
EEG = pop_importdata('dataformat','array','nbchan',size(data,1),'data','data','setname',basename,'srate',fs,'pnts',0,'xmin',0);
evalin('base','clear data');

%import event information from last channel
EEG = pop_chanevent(EEG, size(data,1),'edge','leading','edgelen',1);

%load channel location information from file
EEG = fixegilocs(EEG,[chanlocpath chanlocfile]);

%rename events
for e = 1:length(EEG.event)
    switch EEG.event(e).type
        case 1
            EEG.event(e).type = 'Mv1 ';
        case 2
            EEG.event(e).type = 'Mv2 ';
        case 3
            EEG.event(e).type = 'Rst ';
    end
end

EEG = eeg_checkset(EEG);

%remove unwanted channels
chanexcl = [1,8,14,17,21,25,32,38,43,44,48,49,56,63,64,68,69,73,74,81,82,88,89,94,95,99,107,113,114,119,120,121,125,126,127,128];
%chanexcl = [];
fprintf('Removing excluded channels.\n');
EEG = pop_select(EEG,'nochannel',chanexcl);

%Downsample to 250Hz
if EEG.srate > 250
    EEG = pop_resample(EEG,250);
end

%bandpass filter data
locutoff = 1; hicutoff = 40;
fprintf('Filtering between %d-%dHz.\n',locutoff,hicutoff);
EEG = pop_eegfilt(EEG,locutoff,0);
EEG = pop_eegfilt(EEG,0,hicutoff);

%save the data set to file
EEG.filepath = filepath;
EEG.setname = sprintf('%s_orig',basename);
EEG.filename = sprintf('%s_orig.set',basename);

fprintf('Saving %s%s.\n', EEG.filepath, EEG.filename);
pop_saveset(EEG,'filename', EEG.filename, 'filepath', EEG.filepath);
