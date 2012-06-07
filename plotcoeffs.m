function plotcoeffs(EEG,AllCoeffs)

loadpaths

splinefile = '129_spline.spl';
chanlocfile = 'GSN-HydroCel-129.sfp';
chanlocs = pop_readlocs([chanlocpath chanlocfile]);
chanlocs = chanlocs(4:end);

origchan = zeros(1,length(EEG.origchan));
for c = 1:length(EEG.origchan)
    origchan(c) = find(strcmp(EEG.origchan{c},{chanlocs.labels}));
end


numchan = length(EEG.origchan);
numbands = size(EEG.data,1)/numchan;
meanwv = zeros(length(AllCoeffs),numchan);

for i = 1:length(AllCoeffs)
    
    currentb = AllCoeffs{i};
    currentvectors = currentb.SupportVectors;
    
    weightvectors = currentvectors' * currentb.Alpha;
    bandnum = sort(repmat(1:numbands,1,numchan));
    [~,maxidx] = max(abs(weightvectors));
    maxband = bandnum(maxidx);

    weightvectors = weightvectors(bandnum==maxband);
    meanwv(i,:) = weightvectors';
end

plotvals = zeros(1,129);

plotvals(origchan) = mean(meanwv,1);

figure('Color','white');
subplot(1,2,1);
headplot(plotvals,[chanlocpath splinefile],'electrodes','off','view',[0 90]);
subplot(1,2,2);
headplot(plotvals,[chanlocpath splinefile],'electrodes','off','view',[-136 44]); zoom(1.5);
