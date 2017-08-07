classdef mvObject < handle
    % MVOBJECT is a 'virtual' class : all subclasses (exam/serie/volume) contain this virtual class methods and attributes
    
    properties
        
        name = '' % name of the directory/file
        path = '' % path of the directory/file
        
        tag  = '' % tag of the subclass object (exam/serie/volume)
        
    end
    
    methods
        
        % --- Constructor -------------------------------------------------
        % no constructor : this is an abstract object
        % -----------------------------------------------------------------
        
    end
    
end % classdef
