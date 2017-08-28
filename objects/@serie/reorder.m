function serieArray = reorder( serieArray, kind )
% REORDER by 'kind'.
% 'kind' = 'name', 'path', 'tag'

%% Check input arguments

AssertIsSerieArray(serieArray)
assert( nargin>1 && ( ischar(kind) ) && ~isempty(kind) , 'kind must be defined and a non-empty char ')


%% Sort

[~,I] = sort( cellstr( char(serieArray.(kind)) ) ) ;

serieArray = serieArray(I);

end % function
