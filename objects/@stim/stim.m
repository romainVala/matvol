classdef stim < mvObject
    % STIM object construction is encapsulated inside [ exam.addVolumes ].
    
    properties
        
        exam   = exam.empty  % exam   associated with this serie (See @serie object)
        serie  = serie.empty % series associated with this exam  (See @exam  object)
        
    end
    
    methods
        
        % --- Constructor -------------------------------------------------
        function obj = stim(inputPath, tag, examObj, serieObj)
            %
            
            % Input args ?
            if nargin > 0
                
                [pathstr,name, ~] = get_parent_path(inputPath);
                obj.name = name;                                               % name of the file
                obj.path = [pathstr repmat(filesep,[size(pathstr,1) 1]) name]; % path of the file
                obj.tag  = tag;                                                % tag of the stim : s, wms, f, rf, swrf, ...
                
                % If an @exam object is presented as input argument,
                % incorporate it's pointer inside the created @stim
                % object.
                if exist('examObj','var')
                    obj.exam = examObj;
                end
                
                % If an @serie object is presented as input argument,
                % incorporate it's pointer inside the created @stim
                % object.
                if exist('serieObj','var')
                    obj.serie = serieObj;
                end
                
            end
            
        end % ctor
        % -----------------------------------------------------------------
        
        
    end
    
end % classdef
