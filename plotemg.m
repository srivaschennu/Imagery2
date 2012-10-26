function plotemg(basename,clim)

loadpaths

EEG = pop_loadset('filepath',filepath,'filename',[basename '.set']);

EEG.chanlocs(1).labels = 'Right Hand EMG';
EEG.chanlocs(2).labels = 'Left Hand EMG';

numtrials = EEG.trials;
numchan = EEG.nbchan;

trialclass = {EEG.event.type};

for t = 1:length(trialclass)
    switch trialclass{t}
        case 'Mv1 '
            trialclass{t} = '1. Right Hand';
        case 'Mv2 '
            trialclass{t} = '2. Left Hand';
        case 'Rst '
            trialclass{t} = '3. Rest';
    end
end

classtypes = unique(trialclass);
numclass = length(classtypes);

labels = false(numtrials,numclass);
for t = 1:numtrials
    labels(t,:) = strcmp(trialclass{t},classtypes);
end

figure;
figpos = get(gcf,'Position');
set(gcf,'Position',[figpos(1) figpos(2) figpos(3)*numchan (figpos(4)*numclass)/1.5]);

plotidx = 1;
for cl = 1:numclass
    for chan = 1:numchan
        subplot(numclass,numchan,plotidx);
        %erpimage(squeeze(EEG.data(chan,:,labels(:,cl))),[],EEG.times);
        imagesc(EEG.times,1:sum(labels(:,cl)),squeeze(EEG.data(chan,:,labels(:,cl)))',clim); colorbar
        hold all
        
        if plotidx == 1
            xlabel('Time (ms)','FontSize',16);
        end
        if mod(plotidx,numchan) == 1
            ylabel(sprintf('%s',classtypes{cl}),'FontSize',16);
        end
        if plotidx <= numchan
            title(EEG.chanlocs(chan).labels,'FontSize',16);
        end
        
        set(gca,'FontSize',16);
        plotidx = plotidx+1;
    end
end
set(gcf,'Color','white','Name',basename);