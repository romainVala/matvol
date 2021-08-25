classdef mvFile < mvObject
    % MVFILE is like a virtual class : you don't use it directly, but its
    % the base for sub-classes Sub-classes are : @json @stim @rp @physio
    
    properties
        
        exam   = exam.empty  % exam   associated with this serie (See @serie object)
        serie  = serie.empty % series associated with this exam  (See @exam  object)
        
        subdir = ''          % name of the subdir, in regards of the @serie that contains this @volume
        
    end
    
    methods
        
        % --- Constructor -------------------------------------------------
        function self = mvFile(inputPath, tag, examObj, serieObj, subdir)
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
                
                % Subdir ?
                if exist('subdir','var')
                    self.subdir = subdir;
                end
                
            end
            
        end % ctor
        % -----------------------------------------------------------------
        
        
    end
    
end % classdef
