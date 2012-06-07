function plotmaps(basename,bestband)

loadpaths

splinefile = '129_spline.spl';
chanlocfile = 'GSN-HydroCel-129.sfp';
chanlocs = pop_readlocs([chanlocpath chanlocfile]);
chanlocs = chanlocs(4:end);

load(sprintf('%s.mat',basename));
numfeatures = size(features,1);
numchan = length(EEG.origchan);
numbands = numfeatures/numchan;

bandnum = sort(repmat(1:numbands,1,numchan));

origchan = zeros(1,length(EEG.origchan));
for c = 1:length(EEG.origchan)
    origchan(c) = find(strcmp(EEG.origchan{c},{chanlocs.labels}));
end

for t = 1:length(timevals)
    plotvals = zeros(1,129);
    
    class1vals = mean(features(bandnum == bestband,t,labels == 1),3)';
    class2vals = mean(features(bandnum == bestband,t,labels == 0),3)';
    plotvals(origchan) = class1vals - class2vals;
    
    figure('Color','white');
    subplot(1,2,1);
    headplot(plotvals,[chanlocpath splinefile],'electrodes','off','view',[0 90]);
    subplot(1,2,2);
    headplot(plotvals,[chanlocpath splinefile],'electrodes','off','view',[-136 44]); zoom(1.5);
    saveas(gcf,sprintf('figures/%s_%d.tiff',basename,t));
    close(gcf);
end