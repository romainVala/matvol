classdef volume < mvFile
    % Use @mvFile as base
    
    methods
        
        function self = volume(varargin)
            
            self = self@mvFile(varargin{:});
            
        end % function
        
    end % methods
    
end % classdef
