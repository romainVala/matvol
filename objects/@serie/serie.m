classdef serie < mvObject
    % SERIE object construction is encapsulated inside [ exam.addSerie ].
    
    properties
        
        volume = volume.empty % volumes associated with this serie
        exam   = exam.empty   % exam    associated with this serie
        stim   = stim.empty   % stim    associated with this serie
        json   = json.empty   % json    associated with this serie
        
        nick = '' % nick = tag *given by the user*, not the one with auto-increment (_001, _002, ...)
        inc  = 1  % when add* methods increments the tag number (_001, _002, ...), this fields is updated
        
        sequence = struct % sequence parameters
        
    end
    
    methods
        
        % --- Constructor -------------------------------------------------
        function self = serie(inputPath, tag, nick, inc, examObj)
            %
            
            % Input args ?
            if nargin > 0
                
                [pathstr,name, ~] = get_parent_path(inputPath);
                self.name = name;                                % directory name
                self.path = fullfile(pathstr,name,filesep);      % path of dirname
                self.tag  = tag;                                 % tag of the serie : anat, T1, run, run1, d60, RS, ...
                self.nick = nick;                                % tag given by the user
                if ~isempty(inc); self.inc = inc; end            % increment, if specified
                
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
