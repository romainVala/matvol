classdef mvObject < handle
    % MVOBJECT is a 'virtual' class : all subclasses (exam/serie/volume/...) contain this virtual class methods and attributes
    
    properties
        
        name  = ''     % name of the directory/file
        path  = ''     % path of the directory/file
        
        tag   = ''     % tag of the subclass object (exam/serie/volume)
        
        cfg   = struct % configuration parameters
        
        other = struct % user can use this structure however he wants
        
    end
    
    methods
        
        % --- Constructor -------------------------------------------------
        % no 'real' constructor : this is a 'virtual' object
        % -----------------------------------------------------------------
        function self =  mvObject
            global mvObject_cfg
            
            % --- cfg ---
            
            if isempty(mvObject_cfg)
                p = matvol_config;             % Load config : you can copy the function matvol_config.m to use your personnal configuration
                mvObject_cfg = p.mvObject_cfg; % Save config in global workspace
            end
            
            self.cfg.allow_duplicate   = mvObject_cfg.allow_duplicate;
            self.cfg.remove_duplicates = mvObject_cfg.remove_duplicates;
            
        end % ctor
        
    end
    
end % classdef
