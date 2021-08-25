function physioArray = getPhysio( serieArray, varargin )
% See also @serie/getFile

physioArray = serieArray.getFile('physio',varargin{:});

end % function
