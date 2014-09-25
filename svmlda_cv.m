function [bestaccu bestsig] = svmlda_cv(EEG,TrainTestMethod,Traininfo)

features = EEG.data;
numfeatures = size(features,1);
numsamples = size(features,2);
numtrials = size(features,3);
numchan = length(EEG.origchan);

fprintf('Calculating log transform of bandpower channels.\n');
features = log10(features);

classtypes = unique(EEG.trialclass);
if length(classtypes) ~= 2
    error('Invalid number of classes found!');
end

labels = zeros(1,numtrials);
for t = 1:numtrials
    labels(t) = strcmp(EEG.trialclass{t},classtypes{1});
end

%%%% KEY PARAMETERS %%%%
actwin = [1 4];
cvruns = 5;
alpha = 0.01;
numperms = 200;
smoothwin = 0.25;
clsfyrtype = 'naivebayes';
%%%%%

timevals = EEG.times;
smoothwin = find(timevals(1,:) - timevals(1) < smoothwin*1000, 1, 'last');
actidx = find(timevals/1000>=actwin(1) & timevals/1000<=actwin(2));

cvstart = 1:round(numtrials/cvruns):numtrials;
if cvstart(end) < numtrials
    cvstart = [cvstart numtrials];
end

switch TrainTestMethod
    
    case 'cv'
        
        fprintf('\nRunning %d-fold CV over %d trials and %d features.\n', cvruns, numtrials, numfeatures);
        
        allaccs = zeros(numsamples,numtrials);
        testaccu = zeros(cvruns,numsamples);
        clsfyr = cell(cvruns,numsamples);
        
        for run = 1:cvruns
            
            testtrials = cvstart(run):cvstart(run+1);
            traintrials = setdiff(1:numtrials,testtrials);
            trainlabels = labels(traintrials)';
            testlabels = labels(testtrials)';
            
            fprintf('Testing trials %d-%d.\n', testtrials(1),testtrials(end));
            for t = 1:numsamples
                
                trainfeatures = squeeze(features(:,t,traintrials))';
                testfeatures = squeeze(features(:,t,testtrials))';
                
                [testres,b] = runclsfyr(clsfyrtype,trainfeatures,trainlabels,testfeatures);
                clsfyr{run,t} = b;
                
                allaccs(t,testtrials) = ~xor(testres > 0, testlabels > 0);
                testaccu(run,t) = (sum(~xor(testres > 0, testlabels > 0))/length(testlabels)) * 100;
                
            end %loop over timepoints
        end %loop over CV runs
        
        out_accu = (sum(allaccs,2)./size(allaccs,2))*100;
        out_accu = out_accu';
        
        % smooth accuracy
        smooth_accu = zeros(size(out_accu));
        for t = 1:numsamples
            swstart = max(1,t-floor(smoothwin/2));
            swstop = min(t+floor(smoothwin/2),size(out_accu,2));
            smooth_accu(t) = mean(out_accu(swstart:swstop),2);
        end
        out_accu = smooth_accu;
        
    case 'bootcv'
        
        fprintf('\nRunning %d randomization tests of %d-fold CV over %d trials and %d features.\n', numperms, cvruns, numtrials, numfeatures);
        
        boot_accu = zeros(numperms+1,numsamples);
        best_boot = zeros(numperms+1,1);
        clsfyr = cell(cvruns,numsamples);
        randlabels = labels;
        
        wb_handle = waitbar(0,'Starting randomization test...');
        for boot = 1:numperms+1
            
            if boot > 1
                waitbar((boot-1)/numperms,wb_handle,sprintf('Randomization test %d of %d...',boot-1,numperms));
                randlabels = randlabels(randperm(length(randlabels)));  % randomisation
            end
            
            allaccs = zeros(numsamples,numtrials);
            for run = 1:cvruns
                
                testtrials = cvstart(run):cvstart(run+1);
                traintrials = setdiff(1:numtrials,testtrials);
                trainlabels = randlabels(traintrials)';
                testlabels = randlabels(testtrials)';
                
                for t = 1:numsamples
                    
                    trainfeatures = squeeze(features(:,t,traintrials))';
                    testfeatures = squeeze(features(:,t,testtrials))';
                    
                    [testres,b] = runclsfyr(clsfyrtype,trainfeatures,trainlabels,testfeatures);
                    if boot == 1
                        clsfyr{run,t} = b;
                    end
                    
                    allaccs(t,testtrials) = ~xor(testres > 0, testlabels > 0);
                    testaccu(run,t) = (sum(~xor(testres > 0, testlabels > 0))/length(testlabels)) * 100;
                    
                end %loop over timepoints
            end %loop over CV runs
            
            out_accu = (sum(allaccs,2)./size(allaccs,2))*100;
            out_accu = out_accu';
            
            % smooth accuracy
            smooth_accu = zeros(size(out_accu));
            for t = 1:numsamples
                swstart = max(1,t-floor(smoothwin/2));
                swstop = min(t+floor(smoothwin/2),size(out_accu,2));
                smooth_accu(t) = mean(out_accu(swstart:swstop),2);
            end
            boot_accu(boot,:) = smooth_accu;
            best_boot(boot) = max(boot_accu(boot,actidx));
        end
        close(wb_handle);
        
        out_accu = boot_accu(1,:);
        boot_accu = boot_accu(2:end,:);
        best_boot = best_boot(2:end);
        boot_sig = zeros(1,numsamples);
        for t = 1:numsamples
            boot_sig(t) = sum(best_boot >= out_accu(t))/length(best_boot);
        end
        
        %     case 'train'
        %
        %         testaccu = zeros(1,numsamples);
        %
        %         for t = 1:numsamples
        %
        %             trainfeatures = squeeze(features(:,t,:))';
        %             testfeatures = squeeze(features(:,t,:))';
        %             trainlabels = labels';
        %             testlabels = labels';
        %
        %             %normalise for SVM
        %             for feat = 1:size(trainfeatures,2)
        %                 meanfeats(feat) = mean(trainfeatures(:,feat));
        %                 stdfeats(feat) = std(trainfeatures(:,feat));
        %                 normtrainfeats(:,feat) = (trainfeatures(:,feat) - meanfeats(feat)) ./ stdfeats(feat);
        %             end
        %             trainfeatures = normtrainfeats;
        %
        %             for feat = 1:size(testfeatures,2)
        %                 normtestfeats(:,feat) = (testfeatures(:,feat) - mean(meanfeats(feat))) ./ mean(stdfeats(feat));
        %             end
        %             testfeatures = normtestfeats;
        %             clear meanfeats stdfeats normtrainfeats normtestfeats;
        %
        %
        %             b = svmtrain(trainfeatures,trainlabels,'autoscale','false');
        %             testres = svmclassify(b,testfeatures);
        %
        %             [~,f] = svmdecision(testfeatures,b);
        %             alldecisions = [alldecisions f'];
        %             alllabels = [alllabels testlabels'];
        %
        %
        % %             traintrials = 1:numtrials;
        % %             testtrials = 1:numtrials;
        % %
        % %             b = glmfit(trainfeatures,trainlabels,'binomial');
        % %             testres = round(glmval(b,testfeatures,'logit'));
        %
        % %             WM{t} = b;
        %             %                 b = NaiveBayes.fit(trainfeatures,trainlabels);
        %             %                 testres = b.predict(testfeatures);
        %             %
        %             %                 testres = classify(testfeatures,trainfeatures,trainlabels,'diagquadratic');
        %
        %
        %             allaccs(t,testtrials) = ~xor(testres > 0, testlabels > 0);
        %             testaccu(t) = (sum(~xor(testres > 0, testlabels > 0))/length(testlabels)) * 100;
        %             out_accu(t) = (sum(allaccs(t,:),2)./size(allaccs(t,:),2))*100;
        %
        %         end
        %
        %         % smooth accuracy
        %         smooth_accu = zeros(size(out_accu));
        %         for t = 1:numsamples
        %             swstart = max(1,t-floor(smoothwin/2));
        %             swstop = min(t+floor(smoothwin/2),size(out_accu,2));
        %             smooth_accu(t) = mean(out_accu(swstart:swstop),2);
        %         end
        %         out_accu = smooth_accu;
        %         save([EEG.setname '_train.mat'],'WM','alldecisions','out_accu','timevals');
        %
        %     case 'test'
        %
        %         load([Traininfo '_train.mat']);
        %
        %         %% get best classifier
        %         newwins = wins;
        %         targetwin = find(and(newwins(:,2)>actwin(1),newwins(:,2)<actwin(2)));
        %         [~,maxacc] = max(out_accu(targetwin));
        %         b = WM{targetwin(maxacc)};
        %         %%
        %         testaccu = zeros(1,numsamples);
        %         out_accu = zeros(1,numsamples);
        %
        %         for t = 1:numsamples
        %
        %             testfeatures = squeeze(features(:,t,:))';
        %
        %             %                 %% normalise for SVM
        %             %                 for feat = 1:size(trainfeatures,2)
        %             %                     meanfeats(feat) = mean(trainfeatures(:,feat));
        %             %                     stdfeats(feat) = std(trainfeatures(:,feat));
        %             %                     normtrainfeats(:,feat) = (trainfeatures(:,feat) - meanfeats(feat)) ./ stdfeats(feat);
        %             %                 end
        %             %                 trainfeatures = normtrainfeats;
        %             %
        %             %                 for feat = 1:size(testfeatures,2)
        %             %                     normtestfeats(:,feat) = (testfeatures(:,feat) - mean(meanfeats(feat))) ./ mean(stdfeats(feat));
        %             %                 end
        %             %                 testfeatures = normtestfeats;
        %             %                 clear meanfeats stdfeats normtrainfeats normtestfeats;
        %             %                 %
        %             %
        %             %                 b = svmtrain(trainfeatures,trainlabels,'autoscale','false');
        %             %                 clsfyr{run} = b;
        %             %                 testres = svmclassify(b,testfeatures);
        %             % %
        %             %                 [~,f] = svmdecision(testfeatures,b);
        %             %                 alldecisions = [alldecisions f'];
        %             %                 alllabels = [alllabels testlabels'];
        %
        %             testlabels = labels';
        %             testtrials = 1:numtrials;
        %
        %             testres = round(glmval(b,testfeatures,'logit'));
        %
        %             %             testres = round(glmval(WM{t},testfeatures,'logit'));
        %
        %             %                 b = NaiveBayes.fit(trainfeatures,trainlabels);
        %             %                 testres = b.predict(testfeatures);
        %             %
        %             %                 testres = classify(testfeatures,trainfeatures,trainlabels,'diagquadratic');
        %
        %
        %             allaccs(t,testtrials) = ~xor(testres > 0, testlabels > 0);
        %             testaccu(t) = (sum(~xor(testres > 0, testlabels > 0))/length(testlabels)) * 100;
        %             out_accu(t) = sum(allaccs(t,:),2)./size(allaccs(t,:),2);
        %
        %         end
        %
        %         %% smooth accuracy
        %         winlen = length(find(wins(:,2) < wins(1,2)+smoothwin))+1;
        %
        %         smoothacc = zeros(1,size(wins,1)-winlen);
        %
        %         for smwin = 1:length(smoothacc)
        %
        %             startp = smwin;
        %             stopp = smwin+winlen;
        %             smoothacc(smwin) = mean(out_accu(startp:stopp));
        %
        %         end
        %
        %         out_accu = smoothacc;
        %         wins = wins(winlen+1:end,:);
        %
        %         save([EEG.setname '_accu.mat'],'smoothacc','wins');
        
        
end

EEG.data = [];

if strcmp(TrainTestMethod,'train')
    save([eeg.setname '.mat'],'eeg','features','labels','out_accu','timevals','clsfyr');
end

% if strcmp(TrainTestMethod,'bootcv')
%     save([EEG.setname '.mat'],'boot_accu','best_boot','boot_sig','-append');
% end
    
%% plot figures
ylim = [50 100];
xlim = [timevals(1)/1000 timevals(end)/1000];

scrsize = get(0,'ScreenSize');
fsize = [1000 660];
figure('Position',[(scrsize(3)-fsize(1))/2 (scrsize(4)-fsize(2))/2 fsize(1) fsize(2)],...
    'Name',EEG.setname,'NumberTitle','off');

plot(timevals/1000,out_accu,'Marker','.','LineWidth',3);
set(gca,'YLim',ylim);
set(gca,'XLim',xlim);
line([0 0],[0 ylim(2)],'Color','black');
ylabel('Accuracy (%)');
xlabel('Time (s)');

line([xlim(1) xlim(2)],[90 90],'Color','green');
line([xlim(1) xlim(2)],[70 70],'Color','yellow');
line([actwin(1) actwin(1)],[ylim(1) ylim(2)],'Color','blue')
line([actwin(2) actwin(2)],[ylim(1) ylim(2)],'Color','blue')

text(xlim(2)+0.2,91,'EXCELLENT','Rotation',90);
text(xlim(2)+0.2,78,'GOOD','Rotation',90);
text(xlim(2)+0.2,55,'MORE TRAINING','Rotation',90);

title(sprintf('Single-trial classification accuracy for %s', EEG.setname), 'Interpreter', 'none');
grid on
box on
set(gcf,'Name',sprintf('%s: %s vs %s',EEG.setname,classtypes{1},classtypes{2}));

if strcmp(TrainTestMethod,'bootcv')
    for t = 1:numsamples
        if boot_sig(t) <= alpha
            text(timevals(t)/1000,ylim(1),'*','Color','red');
        end
    end
    bestsig = min(boot_sig(actidx));
else
    bestsig = [];
end


%%%%%%% plot scalp maps
[bestaccu,bestaccuidx] = max(out_accu(actidx));
bestaccuidx = actidx(bestaccuidx);

loadpaths
splinefile = '129_spline.spl';
chanlocfile = 'GSN-HydroCel-129.sfp';
chanlocs = pop_readlocs([chanlocpath chanlocfile]);
chanlocs = chanlocs(4:end);
numbands = numfeatures/numchan;
bandnum = sort(repmat(1:numbands,1,numchan));
plotbands = 1:numbands;
plotbands = 4;

origchan = zeros(1,length(EEG.origchan));
for c = 1:length(EEG.origchan)
    origchan(c) = find(strcmp(EEG.origchan{c},{chanlocs.labels}));
end

figure('Color','white');
figpos = get(gcf,'Position');
figpos(4) = figpos(4)*length(plotbands);
set(gcf,'Position',figpos);
plotidx = 1;

for b = plotbands
    plotvals = zeros(1,129);
    
    class1vals = mean(features(bandnum == b,bestaccuidx,labels == 1),3)';
    class2vals = mean(features(bandnum == b,bestaccuidx,labels == 0),3)';
    plotvals(origchan) = class1vals - class2vals;
    
    subplot(length(plotbands),2,plotidx);
    headplot(plotvals,[chanlocpath splinefile],'electrodes','off','view',[0 90],'maplimits',[-0.5 0.5]);
    subplot(length(plotbands),2,plotidx+1);
    headplot(plotvals,[chanlocpath splinefile],'electrodes','off','view',[-136 44],'maplimits',[-0.5 0.5]); zoom(1.5);
    
    plotidx = plotidx+2;
end

set(gcf,'Name',sprintf('%s: %s vs %s',EEG.setname,classtypes{1},classtypes{2}));

if strcmp(TrainTestMethod,'bootcv')
    fprintf('%s: %s vs %s best accuracy at %.2f sec: %.1f%% (p = %.3f) across %d trials\n',...
        EEG.setname,classtypes{1},classtypes{2},timevals(bestaccuidx)/1000,bestaccu,bestsig,numtrials);
else
    fprintf('%s: %s vs %s best accuracy at %.2f sec: %.1f%% across %d trials\n',...
        EEG.setname,classtypes{1},classtypes{2},timevals(bestaccuidx)/1000,bestaccu,numtrials);
end

fprintf('\n');


function [testres,b] = runclsfyr(clsfyrtype,trainfeatures,trainlabels,testfeatures)

switch clsfyrtype
    
    case 'svm'
        for feat = 1:size(trainfeatures,2)
            meanfeats(feat) = mean(trainfeatures(:,feat));
            stdfeats(feat) = std(trainfeatures(:,feat));
            normtrainfeats(:,feat) = (trainfeatures(:,feat) - meanfeats(feat)) ./ stdfeats(feat);
        end
        trainfeatures = normtrainfeats;
        
        for feat = 1:size(testfeatures,2)
            normtestfeats(:,feat) = (testfeatures(:,feat) - mean(meanfeats(feat))) ./ mean(stdfeats(feat));
        end
        testfeatures = normtestfeats;
        clear meanfeats stdfeats normtrainfeats normtestfeats;
        
        try
            b = svmtrain(trainfeatures,trainlabels,'autoscale','false');
            testres = svmclassify(b,testfeatures);
        catch err
            if or(strcmp(err.identifier,'stats:svmtrain:NoConvergence'),strcmp(err.identifier,'Bioinfo:svmtrain:NoConvergence'));
                fprintf('No convergence met. Skipping...\n');
                b = [];
                testres = round(rand(length(testlabels),1));
            else
                fprintf('%s\n',err.identifier);
                return;
            end
        end
        
    case 'logistic'
        b = sbmlr(trainfeatures,cat(2,trainlabels,~trainlabels));
        testres = exp(testfeatures*b);
        testres = testres ./ repmat(sum(testres,2),1,size(testres,2));
        testres = testres(:,1);
        testres = testres >= 0.5;
        
    case 'stepwise'
        [b,~,~,inmodel] = stepwisefit(trainfeatures,trainlabels,'display','off');
        b = b'.*inmodel;
        testres = testfeatures * b';
        
    case 'regress'
        b = regress(trainlabels,trainfeatures);
        testres = testfeatures * b;
        
    case 'naivebayes'
        b = NaiveBayes.fit(trainfeatures,trainlabels);
        testres = b.predict(testfeatures);
        
        
    case 'classify'
        testres = classify(testfeatures,trainfeatures,trainlabels,'diaglinear');
end