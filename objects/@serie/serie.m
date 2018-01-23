classdef serie < mvObject
    % SERIE object construction is encapsulated inside [ exam.addSerie ].
    
    properties
        
        volumes = volume.empty % volumes associated with this serie
        exam    = exam.empty   % exam    associated with this serie
        stim    = stim.empty   % stim    associated with this serie
        
    end
    
    methods
        
        % --- Constructor -------------------------------------------------
        function self = serie(inputPath, tag, examObj)
            %
            
            % Input args ?
            if nargin > 0
                
                [pathstr,name, ~] = get_parent_path(inputPath);
                self.name = name;                                           % directory name
                self.path = fullfile(pathstr,name,filesep);                 % path of dirname
                self.tag  = tag;                                            % tag of the serie : anat, T1, run, run1, d60, RS, ...
                
                % If an @exam object is presented as input argument,
                % incorporate it's pointer inside the created @serie
                % object.
                if exist('examObj','var')
                    self.exam = examObj;
                end
                
            end
            
        end % ctor
        % -----------------------------------------------------------------
        
    end
    
end % classdef
