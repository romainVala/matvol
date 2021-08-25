function varargout = addVolume( serieArray, varargin )
% See also @serie/addFile

if nargout
    varargout = serieArray.addFile('volume',varargin{:});
else
    serieArray.addFile('volume',varargin{:});
end

end % function
