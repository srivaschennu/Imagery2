function EEG = epochdata(filename,icamode)

if ~exist('icamode','var') || isempty(icamode)
    icamode = 0;
end

eventlist = {
    'Mv1'
    'Mv2'
    'Rst'
    };

loadpaths

if ischar(filename)
    EEG = pop_loadset('filename', [filename '_orig.set'], 'filepath', filepath);
else
    EEG = filename;
end

fprintf('Epoching and baselining.\n');

EEG = pop_epoch(EEG,eventlist,[0 5]);

EEG = eeg_checkset(EEG);

if ischar(filename)
    EEG.setname = filename;
    
    if icamode
        EEG.filename = [filename '_epochs.set'];
    else
        EEG.filename = [filename '.set'];
    end
    
    fprintf('Saving set %s%s.\n',filepath,EEG.filename);
    pop_saveset(EEG,'filename', EEG.filename, 'filepath', filepath);
end