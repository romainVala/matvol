classdef exam < mvObject
    % EXAM object behave construction behave the same as [ get_subdir_regex ]
    %
    % Syntax  : examArray = exam(baseDirectory, reg_ex1, reg_ex2, reg_ex3, ...)
    % Example : examArray = exam('/dir/to/subjects/', 'SubjectNameREGEX')
    
    properties
        
        series = serie.empty % series associated with this exam (See @serie object)
        
        is_incomplete = [];  % this flag will be set to 1 if missing series/volumes
        
    end
    
    methods
        
        % --- Constructor -------------------------------------------------
        function examArray = exam(indir, reg_ex, varargin)
            %
            
            % Input args ?
            if nargin > 0
                
                % Fetch dir list recursibley with regex
                dirList = get_subdir_regex(indir, reg_ex, varargin{:});
                
                % Create an array of @exam objects, corresponding to each dir in the list
                for idx = 1 : length(dirList)
                    
                    [pathstr,name, ~] = get_parent_path(dirList{idx});
                    examArray(idx,1).name = name; %#ok<*AGROW>              % directory name
                    examArray(idx,1).tag  = name;                           % initialization of the tag
                    examArray(idx,1).path = fullfile(pathstr,name,filesep); % path of dirname
                    
                    % NB : series field is an empty @serie object at the creation of the exam
                    
                end
                
            end
            
        end % ctor
        % -----------------------------------------------------------------
        
    end
    
end % classdef
