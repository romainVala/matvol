function plot( stimArray )
%PLOTSPMNOD

for st = 1 : numel(stimArray)
    
    l = load(stimArray(st).path);
    plotSPMnod(l.names,l.onsets,l.durations)
    set(gcf,'Name',stimArray(st).path)
    
end

end % function
