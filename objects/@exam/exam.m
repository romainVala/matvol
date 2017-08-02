classdef exam < handle
    % EXAM object behave construction behave the same as get_subdir_regex
    %
    % Syntax  : examArray = exam(baseDirectory, reg_ex1, reg_ex2, reg_ex3, ...)
    % Example : examArray = exam('/dir/to/subject/', 'SubjectNameREGEX')
    
    properties
        
        name = '' % directory name
        path = '' % path of dirname
        
        series = serie.empty % series associated with this exam (See @serie object)
        
    end
    
    methods
        
        % --- Constructor -------------------------------------------------
        function examArray = exam(indir, reg_ex, varargin)
            %
            
            % Input args ?
            if nargin > 0
                
                % Fetch dir list recursibley with regex
                dirList = get_subdir_regex(indir, reg_ex, varargin{:});
                
                % Create an array of @exam objects, corresponding to each
                % dir in the list
                for idx = 1 : length(dirList)
                    
                    [pathstr,name, ~] = get_parent_path(dirList{idx});
                    examArray(idx,1).name = name; %#ok<*AGROW>
                    examArray(idx,1).path = fullfile(pathstr,name,filesep);
                    
                    % NB : series field remains empty at the creaion of the exam
                    
                end
                
            end
            
        end % ctor
        % -----------------------------------------------------------------
        
    end
    
end % classdef
