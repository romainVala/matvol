classdef volume < mvObject
    % VOLUME object construction is encapsulated inside [ exam.addVolume ] or [ seie.addVolume ].
    % VOLUME can have multiples elements in path, for multiple files
    
    properties
        
        exam   = exam.empty  % exam   associated with this serie (See @serie object)
        serie  = serie.empty % series associated with this exam  (See @exam  object)
        
    end
    
    methods
        
        % --- Constructor -------------------------------------------------
        function self = volume(inputPath, tag, examObj, serieObj)
            %
            
            % Input args ?
            if nargin > 0
                
                [pathstr,name, ~] = get_parent_path(inputPath);
                self.name = name;                                               % name of the file
                self.path = [pathstr repmat(filesep,[size(pathstr,1) 1]) name]; % path of the file
                self.tag  = tag;                                                % tag of the volume : s, wms, f, rf, swrf, ...
                
                % If an @exam object is presented as input argument,
                % incorporate it's pointer inside the created @volume
                % object.
                if exist('examObj','var')
                    self.exam = examObj;
                end
                
                % If an @serie object is presented as input argument,
                % incorporate it's pointer inside the created @volume
                % object.
                if exist('serieObj','var')
                    self.serie = serieObj;
                end
                
            end
            
        end % ctor
        % -----------------------------------------------------------------
        
        
    end
    
end % classdef
