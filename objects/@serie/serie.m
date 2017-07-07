classdef serie < handle
    
    properties
        
        name % directory name
        path % path of dirname
        
        tag  % tag of the serie : anat, T1, run, run1, d60, RS, ...
        
        exam = exam.empty % exam associatedthis serie
        
    end
    
    methods
        
        % --- Constructor -------------------------------------------------
        function obj = serie(inputPath, tag, examObj)
            if nargin > 0
                
                [pathstr,name, ~] = get_parent_path(inputPath);
                obj.name = name;
                obj.path = fullfile(pathstr,name,filesep);
                obj.tag  = tag;
                
                if exist('examObj','var')
                    obj.exam = examObj;
                end
                
            end
        end
        % -----------------------------------------------------------------
        
    end
    
end % classdef
