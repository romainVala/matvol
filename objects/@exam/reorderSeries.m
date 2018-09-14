function examArray = reorderSeries( examArray, kind )
% REORDERSERIES
% See help serie.reorder


%% Check input arguments

if nargin < 2
    kind = 'name';
end


%% Do the reorder over all exams

for ex = 1 : numel(examArray)
    examArray(ex).serie = examArray(ex).serie.reorder(kind);
end


end % function
