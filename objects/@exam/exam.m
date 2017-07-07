classdef exam < handle
    
    properties
        
        name % directory name
        path % path of dirname
        
        series = serie.empty % series associated with this exam (See @serie object)
        
    end
    
    methods
        
        % --- Constructor -------------------------------------------------
        function examArray = exam(indir, reg_ex, varargin)
            if nargin > 0
                dirList = get_subdir_regex(indir, reg_ex, varargin{:});
                for idx = 1 : length(dirList)
                    [pathstr,name, ~] = get_parent_path(dirList{idx});
                    examArray(idx).name = name; %#ok<*AGROW>
                    examArray(idx).path = fullfile(pathstr,name,filesep);
                end
            end
        end
        % -----------------------------------------------------------------
        
    end
    
end % classdef
