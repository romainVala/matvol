function reorderSeries( examArray, kind )
% REORDERSERIES
% See help serie.reorder


%% Check input arguments

AssertIsExamArray(examArray)

if nargin < 2
    kind = 'name';
end


%% Do the reorder over all exams

for ex = 1 : numel(examArray)
    examArray(ex).series = examArray(ex).series.reorder(kind);
end


end % function
