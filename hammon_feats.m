function EEG = hammon_feats(EEG,wins) % refers to description in Hammon et al., IEEE Signal proc Jan 2008 i.e. to average squared amplitude across large windows

EEG.times = wins(:,1)' .* 1000;

wins = floor(wins .* EEG.srate);

wins(wins == 0) = 1;

outdata = zeros(size(EEG.data,1),size(wins,1),size(EEG.data,3));

for win = 1:size(wins,1)
    outdata(:,win,:) = mean(EEG.data(:,wins(win,1):wins(win,2),:),2);
end

EEG.data = outdata;
EEG.pnts = size(EEG.data,2);
