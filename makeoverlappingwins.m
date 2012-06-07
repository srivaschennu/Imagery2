function wins = makeoverlappingwins(startpoint,winlength,endpoint,step)

wins(2,:) = startpoint+winlength:step:endpoint;
wins(1,:) = wins(2,:) - winlength;

wins = wins';