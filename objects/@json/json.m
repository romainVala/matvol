classdef json < mvFile
    % Use @mvFile as base
    
    methods
        
        function self = json(varargin)
            
            self = self@mvFile(varargin{:});
            
        end % function
        
    end % methods
    
end % classdef
