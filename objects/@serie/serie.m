classdef serie < mvObject
    % SERIE object construction is encapsulated inside [ exam.addSeries ].
    
    properties
        
        volumes = volume.empty % volumes associated with this serie
        exam    = exam.empty   % exam    associated with this serie
        stim    = stim.empty   % stim    associated with this serie
        
    end
    
    methods
        
        % --- Constructor -------------------------------------------------
        function obj = serie(inputPath, tag, examObj)
            %
            
            % Input args ?
            if nargin > 0
                
                [pathstr,name, ~] = get_parent_path(inputPath);
                obj.name = name;                                           % directory name
                obj.path = fullfile(pathstr,name,filesep);                 % path of dirname
                obj.tag  = tag;                                            % tag of the serie : anat, T1, run, run1, d60, RS, ...
                
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
