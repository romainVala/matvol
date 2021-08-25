function volumeArray = getPhysio( serieArray, varargin )
% See also @serie/addFile

volumeArray = serieArray.getFile('physio',varargin{:});

end % function
