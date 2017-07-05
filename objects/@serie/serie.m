classdef serie < handle
    %SERIE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
        name % directory name
        path % path of dirname
        exam % exam associatedthis serie
        
    end
    
    methods
        
        function obj = serie(inputPath, examObj)
            if nargin > 0
                
                [pathstr,name, ~] = get_parent_path(inputPath);
                obj.name = name;
                obj.path = fullfile(pathstr,name);
                
                if nargin > 1 
                    obj.exam = examObj;
                end
                
            end
        end
        
    end
    
end % classdef
