classdef mvObject < handle
    % MVOBJECT is a 'virtual' class : all subclasses (exam/serie/volume) contain this virtual class methods and attributes
    
    properties
        
        name = ''     % name of the directory/file
        path = ''     % path of the directory/file
        
        tag  = ''     % tag of the subclass object (exam/serie/volume)
        
        cfg  = struct % configuration parameters
        
    end
    
    methods
        
        % --- Constructor -------------------------------------------------
        % no 'real' constructor : this is a 'virtial' object
        % -----------------------------------------------------------------
        function obj =  mvObject
            
            % cfg
            obj.cfg.allow_duplicate = 0; % Do not allow adding dupplicate items
            
        end % ctor
        
    end
    
end % classdef
