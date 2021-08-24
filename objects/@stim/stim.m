classdef stim < mvFile
    % Use @mvFile as base
    
    methods
        
        function self = stim(varargin)
            
            self = self@mvFile(varargin{:});
            
        end % function
        
    end % methods
    
end % classdef
