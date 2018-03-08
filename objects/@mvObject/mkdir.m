function out = mkdir( mvArray , varargin )
%MKDIR creates dir contained in varargin, starting for the current self.path
% If the self.path is a dir , a subdir will be created.
% If the self.path is a file, a subdir will be created next to it.
%
%   exemple :
%       mvArray.mkdir('subdir1','subdir2',..., 'subdirN'           )
%       mvArray.mkdir('subdir1','subdir2',...,{'subdirA','subdirB'})
%
%

assert( ~isempty(varargin)  , 'subdirs are required' )

% Restriction : only the last argument can be cellstr for multiple mkdir
for v =  1 : length(varargin)
    if v ~= length(varargin)
        assert( ischar(varargin{v}) , 'arguments must be char' )
    else % the last one
        assert( ischar(varargin{v})||iscellstr(varargin{v}) , 'last argument can be char or cellstr' )
    end
end

if length(varargin) == 1
    intermediatDir = '';
    lastDir        = fullfile(varargin{end});
else
    intermediatDir = fullfile(varargin{1:end-1});
    lastDir        = fullfile(varargin{end});
end

out = cell(numel(mvArray),1);

for idx = 1 : numel(mvArray)
    
    switch exist(mvArray(idx).path) %#ok<EXIST>
        case 0 % nothing
            error('%s is not valid', mvArray(idx).path)
        case 2 % file
            baseDir = get_parent_path(mvArray(idx).path);
        case 7 % dir
            baseDir = mvArray(idx).path;
        otherwise
            error('Nature not defined for %s', mvArray(idx).path)
    end
    
    out{idx} = char(r_mkdir(baseDir,fullfile(intermediatDir,lastDir)));
    
end

end % function
