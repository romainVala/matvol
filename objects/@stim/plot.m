function plot( stimArray )
%PLOTSPMNOD

res = which('plotSPMnod.m');
if isempty(res)
    warning('No plotSPMnod.m ffunction found in matmab paths.')
    warning('Get it at https://github.com/benoitberanger/StimTemplate')
end

for st = 1 : numel(stimArray)
    
    l = load(stimArray(st).path);
    plotSPMnod(l.names,l.onsets,l.durations)
    set(gcf,'Name',stimArray(st).path)
    
end

end % function
