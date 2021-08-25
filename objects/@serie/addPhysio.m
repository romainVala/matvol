function varargout = addPhysio( serieArray, varargin )
% See also @serie/addFile

if nargout
    varargout = serieArray.addFile('physio',varargin{:});
else
    serieArray.addFile('physio',varargin{:});
end

end % function
