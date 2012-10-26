function [bestaccu sig] = lda(basename,class1,class2,TrainTestMethod,TrainInfo)

loadpaths

if ~exist('TrainInfo','var')
    TrainInfo = [];
end

%% Load Data
fprintf('Loading %s.\n', basename);
EEG = pop_loadset('filepath',filepath,'filename',[basename '.set']);
fprintf('Found %d trials, %d samples, %d channels.\n', EEG.trials, EEG.pnts, EEG.nbchan);

selectevents = {class1,class2};
typematches = zeros(1,length(EEG.event));
for e = 1:length(EEG.event)
    if sum(strcmp(strtrim(EEG.event(e).type),selectevents)) > 0
        typematches(e) = true;
    end
end
fprintf('Selecting classes: keeping %d trials.\n',sum(typematches));
EEG = pop_select(EEG,'trial',find(typematches));
EEG = eeg_checkset(EEG);
EEG.trialclass = {EEG.event.type};

%% downsample data

newRate = 100;
fprintf('Downsampling data to %sHz...\n',num2str(newRate));
EEG = pop_resample(EEG, newRate);
EEG.setname = basename;

if EEG.nbchan == 129 || EEG.nbchan == 91
    EEG.origchan = {'E6','E7','E13','E29','E30','E31','E35','E36','E37','E41','E42','E54','E55','E79','E80','E87','E93','E103','E104','E105','E106','E110','E111','E112','Cz'};
    %EEG.origchan = {'E29','E42','E111','E93','E28','E47','E117','E98'};
    
    origchan = zeros(1,length(EEG.origchan));
    for c = 1:length(EEG.origchan)
        origchan(c) = find(strcmp(EEG.origchan{c},{EEG.chanlocs.labels}));
    end
    
elseif size(EEG.data,1) == 257
    origchan = [8    9   17   43   44   45   52   53   58   65   66   80   81  131  132  144  164  182  184  185  186  195  197  198  257];
end
fprintf('Keeping %d channels.\n', length(origchan));
EEG = pop_select(EEG,'channel',origchan);
% 
% %make bipolar channels
% eogpairs = {
%     'E29'   'E42'
%     'E111'  'E93'
%     'E28'   'E47'
%     'E117'  'E98'
%     };
% 
% fprintf('\nCalculating bipolar channels.\n');
% for p = 1:size(eogpairs,1)
%     ch1idx = find(strcmp(eogpairs{p,1},{EEG.chanlocs.labels}));
%     ch2idx = find(strcmp(eogpairs{p,2},{EEG.chanlocs.labels}));
%     eogdata = EEG.data(ch1idx,:) - EEG.data(ch2idx,:);
%     EEG.data(ch1idx,:) = eogdata;
%     EEG.chanlocs(ch1idx).labels = sprintf('BIP%d',p);
%     EEG = pop_select(EEG,'nochannel',ch2idx);
% end

f_low = 7;
f_step = 6;
f_high = 30;
freqrange = f_low:f_step:f_high;
if freqrange(end) < f_high
    freqrange = [freqrange f_high];
end

fprintf('Calculating bandpower in frequency bands between %d:%d:%dHz\n',f_low,f_step,f_high);
EEG = pfurtscheller_power(EEG,freqrange);

starttime = 0;
endtime = 5;
winlength = 1;
step = 0.05; %1/EEG.srate; %one sample
wins = makeoverlappingwins(starttime,winlength,endtime,step);
EEG = hammon_feats(EEG,wins);

% baseline correct power
% fprintf('Baseline correcting power values...\n');
% bcwin = [0 1.5];
% baseline = and(wins(:,1) >= bcwin(1), wins(:,2) <= bcwin(2));
% blpower = mean(EEG.data(:,baseline,:),2);
% 
% for p = 1:size(EEG.data,2)
%         EEG.data(:,p,:) = EEG.data(:,p,:) ./ blpower;
% end

[bestaccu sig] = svmlda_cv(EEG,TrainTestMethod,TrainInfo);

