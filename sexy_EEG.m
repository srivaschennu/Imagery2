function sexy_EEG(basename)

origchan = sort([6    7   13   29   30   31   35   36   37   41   42   54   55   79   80   87   93  103  104  105  106  110  111  112  129],'ascend');

% load([basename '_tovectors.mat']);
load([basename '_feats.mat']);

% rhvectors = rhvectors(freqband,:,:);
% xmax = max(max(rhvectors));
% xmin = min(min(rhvectors));
% 
% for k = 1:size(features,2);
%    
%     features(:,k,:) = features(:,k,:) ./ mean(features(:,50:99,:),2);   
%     
% end

features = log(features);

freqrange = 1;

classtype = logical(classtype);

rh = features(freqrange:4:end,:,classtype);
to = features(freqrange:4:end,:,~classtype);

rh = squeeze(mean(rh,3));
to = squeeze(mean(to,3));

% rhxmax = max(max(rh));
% rhxmin = min(min(rh));
% toxmax = max(max(to));
% toxmin = min(min(to));

%% plot average for window

% rhplot = mean(rh(:,150:200),2);
% toplot = mean(to(:,150:200),2);

rhplot = rh(:,200);
toplot = to(:,200);
%%

% for i = 250;%50:size(rh,2)
% 
% %     toplot = squeeze(rhvectors(1,:,i));
% %     toplot = toplot./xmax;
%     
%     rhplot = rh(:,i);
%     toplot = to(:,i);
    
    rhplotnew = rhplot - toplot;
    toplotnew = toplot - rhplot;
%     
% %     rhplotnew = log(rhplot ./ toplot);
% %     toplotnew = log(toplot ./ rhplot);
% %     
    rhplotnew(rhplotnew > 0) = 0;
    toplotnew(toplotnew > 0) = 0;   
% %     
    rhplot = rhplotnew;
    toplot = toplotnew;
    
    plotchansRH = zeros(1,129);    
%     plotchansRH = repmat(rhxmax-((rhxmax-rhxmin)/2),1,129);

    plotchansRH(origchan) = rhplot;
    
    plotchansTO = zeros(1,129);
%     plotchansTO = repmat(toxmax-((toxmax-toxmin)/2),1,129);

    plotchansTO(origchan) = toplot;  
    
%     plotchansTO = -plotchansTO;
    
    
    if isempty(find(plotchansRH))
        
        j = figure;
        set(j, 'Position', [1 1 500 500]);
        
        
        headplot(plotchansRH,'129_spline.spl','electrodes','off','view',[-136 44],'maplimits',[-1,1]);
        
%         figfilename = ['sexyfigs/' basename '_rh' sprintf('%03d',i) '.tif'];
%         exportfig(j,figfilename,'Format','TIFF','Color','cmyk');
        close(j);
    else
        
        j = figure;
        set(j, 'Position', [1 1 500 500]);
        
        
        headplot(plotchansRH,'129_spline.spl','electrodes','off','view',[-136 44]);%,'maplimits',[-1,1]);
        
%         figfilename = ['sexyfigs/' basename '_rh' sprintf('%03d',i) '.tif'];
%         exportfig(j,figfilename,'Format','TIFF','Color','cmyk');
%         close(j);
    end
    
    
    
    
    if isempty(find(plotchansTO))
        j = figure;
        set(j, 'Position', [1 1 500 500]);
        
        headplot(plotchansTO,'129_spline.spl','electrodes','off','view',[-136 44],'maplimits',[-1,1]);
        
%         figfilename = ['sexyfigs/' basename '_to' sprintf('%03d',i) '.tif'];
%         exportfig(j,figfilename,'Format','TIFF','Color','cmyk');
%         close(j);
    else
        
        
        
        j = figure;
        set(j, 'Position', [1 1 500 500]);
        
        headplot(plotchansTO,'129_spline.spl','electrodes','off','view',[-136 44]);%,'maplimits',[-1,1]);
        
%         figfilename = ['sexyfigs/' basename '_to' sprintf('%03d',i) '.tif'];
%         exportfig(j,figfilename,'Format','TIFF','Color','cmyk');
%         close(j);
        
    end
    
    
% end

