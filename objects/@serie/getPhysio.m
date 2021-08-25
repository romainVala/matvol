function volumeArray = getPhysio( serieArray, varargin )
% See also @serie/getFile

volumeArray = serieArray.getFile('physio',varargin{:});

end % function
