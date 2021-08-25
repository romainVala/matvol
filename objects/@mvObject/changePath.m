function [ pathArray ] = changePath( mvArray, oldpath, newpath )
%CHANGEPATH change a part of the path in objects, useful when data moved


%% Check input

assert( nargin==3, 'oldpath & newpath must be defined, as char or cellstr' )

AssertIsCharOrCellstr(oldpath)
AssertIsCharOrCellstr(newpath)

oldpath = char(oldpath);
newpath = char(newpath);


%% Routine

% Output
pathArray = cell( size(mvArray) );

classname = class(mvArray);

for idx = 1 : numel( mvArray )
    
    if ~isempty(mvArray(idx).path)
        
        % regexprep
        mvArray(idx).path = char(regexprep(cellstr(mvArray(idx).path), oldpath, newpath));
        
        % Save new path in output
        pathArray{idx} = mvArray(idx).path;
        
        % Recursivity
        switch classname
            case 'exam'
                mvArray(idx).serie.changePath( oldpath, newpath );
                mvArray(idx).model.changePath( oldpath, newpath );
            case 'serie'
                mvArray(idx).volume.changePath( oldpath, newpath );
                mvArray(idx).stim  .changePath( oldpath, newpath );
                mvArray(idx).rp    .changePath( oldpath, newpath );
                mvArray(idx).physio.changePath( oldpath, newpath );
            case 'model'
                % pass
            case 'volume'
                % pass
            case 'stim'
                % pass
            case 'rp'
                % pass
            case 'physio'
                % pass
            otherwise
                warning('non-coded routine for the object')
        end
        
    end
    
end % for

end % function
