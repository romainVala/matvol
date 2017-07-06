classdef exam < handle
    
    properties
        
        name   % directory name
        path   % path of dirname
        
        series = serie.empty % series associated with this exam (See @serie object)
        
    end
    
    methods
        
        function obj = exam(inputPath)
            if nargin > 0
                [pathstr,name, ~] = get_parent_path(inputPath);
                obj.name = name;
                obj.path = fullfile(pathstr,name,filesep);
            end
        end
        
    end
    
end % classdef
