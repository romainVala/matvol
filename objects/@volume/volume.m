classdef volume < handle
    %VOLUME Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
        name = '' % name of the file
        path = '' % path of the file
        
        tag  = '' % tag of the volume : s, wms, f, rf, swrf, ...
        
        exam   = exam.empty  % exam associatedthis serie
        serie  = serie.empty % series associated with this exam (See @serie object)
        
    end
    
    methods
        
        % --- Constructor -------------------------------------------------
        function obj = volume(inputPath, tag, examObj, serieObj)
            %
            
            % Input args ?
            if nargin > 0
                
                [pathstr,name, ~] = get_parent_path(inputPath);
                obj.name = name;
                obj.path = fullfile(pathstr,name);
                obj.tag  = tag;
                
                % If an @exam object is presented as input argument,
                % incorporate it's pointer inside the created @serie
                % object.
                if exist('examObj','var')
                    obj.exam = examObj;
                end
                
                % If an @serie object is presented as input argument,
                % incorporate it's pointer inside the created @volume
                % object.
                if exist('serieObj','var')
                    obj.serie = serieObj;
                end
                
            end
            
        end % ctor
        % -----------------------------------------------------------------
        
        
    end
    
end % classdef
