function batchrun

subjlist = {
    'p1_imagery2'
    'p2_imagery2'
    'p3_imagery2'
    'p4_imagery2'
    };

for s = 1:length(subjlist)
    subjname = subjlist{s};
    
%    dataimport(subjname);
    %epochdata(subjname,0);
    rejartifacts2(subjname,2,2);
end