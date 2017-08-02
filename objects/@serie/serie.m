classdef serie < handle
    % SERIE object construction is encapsulated inside [ exam.addSeries ].
    
    properties
        
        name = '' % directory name
        path = '' % path of dirname
        
        tag  = '' % tag of the serie : anat, T1, run, run1, d60, RS, ...
        
        volumes = volume.empty % volumes associated with this serie
        exam    = exam.empty   % exam    associated with this serie
        
    end
    
    methods
        
        % --- Constructor -------------------------------------------------
        function obj = serie(inputPath, tag, examObj)
            %
            
            % Input args ?
            if nargin > 0
                
                [pathstr,name, ~] = get_parent_path(inputPath);
                obj.name = name;
                obj.path = fullfile(pathstr,name,filesep);
                obj.tag  = tag;
                
                % If an @exam object is presented as input argument,
                % incorporate it's pointer inside the created @serie
                % object.
                if exist('examObj','var')
                    obj.exam = examObj;
                end
                
            end
            
        end % ctor
        % -----------------------------------------------------------------
        
    end
    
end % classdef
