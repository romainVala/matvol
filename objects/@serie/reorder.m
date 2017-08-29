function serieArray = reorder( serieArray, kind )
% REORDER by 'kind'.
% 'kind' = 'name', 'path', 'tag'

%% Check input arguments

AssertIsSerieArray(serieArray)
assert( nargin>1 && ( ischar(kind) ) && ~isempty(kind) , 'kind must be defined and a non-empty char ')


%% Sort

[~,newOrder] = sort( cellstr( char(serieArray.(kind)) ) ) ;

nrSeries = size(char(serieArray.(kind)),1);

% In case of empty 'kind', newOrder=1 (due to sort function) instead of a vector.
% So we force newOrder to be vector.
if nrSeries > length(newOrder)
    newOrder = 1:nrSeries;
end

serieArray = serieArray(newOrder);

end % function
