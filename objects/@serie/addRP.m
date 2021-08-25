function varargout = addRP( serieArray, varargin )
% See also @serie/addFile

if nargout
    varargout = serieArray.addFile('rp',varargin{:});
else
    serieArray.addFile('rp',varargin{:});
end

end % function
