function accutest(basename)

dataimport(basename);
epochdata(basename);
rejartifacts2(basename,2,2);

[Mv1vsRstAccu,Mv1vsRstSig] = lda(basename,'Mv1','Rst','cv');
[Mv2vsRstAccu,Mv1vsRstSig] = lda(basename,'Mv2','Rst','cv');
[Mv1vsMv2Accu,Mv1vsRstSig] = lda(basename,'Mv1','Mv2','cv');