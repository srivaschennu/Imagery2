function EEG = pfurtscheller_power(EEG, freqrange)

% smoothwin = 5; %pnts

outdata = zeros(EEG.nbchan*(length(freqrange)-1),EEG.pnts,EEG.trials);

for cfreq = 1:length(freqrange)-1
   
    tempEEG = pop_eegfilt(EEG,freqrange(cfreq),0, [], [0], 0, 0, 'fir1', 0);  %hipass
    tempEEG = pop_eegfilt(tempEEG,0,freqrange(cfreq+1), [], [0], 0, 0, 'fir1', 0); %lopass
    %tempEEG = pop_eegfilt(EEG,freqrange(cfreq),freqrange(cfreq+1)); %bandpss

    tempEEG.data = reshape(tempEEG.data,EEG.nbchan,EEG.pnts,EEG.trials);
    
%     for i = 1:EEG.pnts-smoothwin
%     
%         smoothdata(:,i,:) = mean(tempEEG.data(:,i:i+smoothwin,:),2);
%     
%     end
    
    outdata((cfreq-1)*EEG.nbchan+1:cfreq*EEG.nbchan,:,:) = tempEEG.data;    
    
end

% %% hilbert?
% for ch = 1:size(outdata,1)
%     for trial = 1:size(outdata,3)
% 
%         outdata(ch,:,trial) = abs(hilbert(outdata(ch,:,trial)));
% 
%     end
% end

outdata = outdata .^2;

EEG.data = outdata;
EEG.pnts = size(EEG.data,2);