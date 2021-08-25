function varargout = addJson( serieArray, varargin )
% See also @serie/addFile

if nargout
    varargout = serieArray.addFile('json',varargin{:});
else
    serieArray.addFile('json',varargin{:});
end

end % function
