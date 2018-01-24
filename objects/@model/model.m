classdef model < mvObject
    % MODEL object construction is encapsulated inside [ exam.addModel ].
    
    properties
        
        exam    = exam.empty   % exam    associated with this serie
        
    end
    
    methods
        
        % --- Constructor -------------------------------------------------
        function self = model(inputPath, tag, examObj)
            %
            
            % Input args ?
            if nargin > 0
                
                [pathstr,name, ~] = get_parent_path(inputPath);
                self.name = name;                   % directory name
                self.path = fullfile(pathstr,name); % path of dirname
                self.tag  = tag;                    % tag of the serie : anat, T1, run, run1, d60, RS, ...
                
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
