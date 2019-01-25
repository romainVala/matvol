classdef exam < mvObject
    % EXAM object behave construction behave the same as [ get_subdir_regex ]
    %
    % Syntax  : examArray = exam(baseDirectory, reg_ex1, reg_ex2, reg_ex3, ...)
    % Example : examArray = exam('/dir/to/subjects/', 'SubjectNameREGEX')
    %
    % Note : if the 'reg_ex' is left empty, a popup will appear to select the directories graphically
    %
    
    properties
        
        serie = serie.empty % series associated with this exam (See @serie object)
        model = model.empty % models associated with this exam (See @model object)
        
        is_incomplete = [];  % this flag will be set to 1 if missing series/volumes
        
    end
    
    methods
        
        % --- Constructor -------------------------------------------------
        function examArray = exam(indirs, reg_ex, varargin)
            %
            
            % Input args ?
            if nargin > 0
                
                if nargin < 2
                    reg_ex = 'graphically';
                end
                
                AssertIsCharOrCellstr(indirs )
                AssertIsCharOrCellstr(reg_ex)
                
                if ischar(indirs), indirs = {indirs};end
                
                idx_append = 0;
                
                for nb_in = 1:length(indirs)
                    indir  = indirs{nb_in};
                    reg_ex = char(reg_ex);
                    
                    % Is indir a real dir ?
                    assert( exist(indir,'dir')==7, 'Dir does not exist : %s', indir )
                    
                    % Fetch dir list recursibley with regex
                    if strcmp(reg_ex,'root')
                        dirList={indir};
                    else
                        dirList = get_subdir_regex(indir, reg_ex, varargin{:});
                    end
                    
                    if numel(dirList) == 0
                        warning('No dir found with regex [ %s ]\n in : %s', ...
                            reg_ex, indir )
                    elseif numel(dirList)==1 && isempty(dirList{1})
                        warning('No dir selected graphically')
                        examArray = exam.empty;
                        return
                    end
                    
                    % Create an array of @exam objects, corresponding to each dir in the list
                    for idx = 1 : length(dirList)
                        
                        [pathstr,name, ~] = get_parent_path(dirList{idx});
                        examArray(idx+idx_append,1).name = name; %#ok<*AGROW>              % directory name
                        examArray(idx+idx_append,1).tag  = name;                           % initialization of the tag
                        examArray(idx+idx_append,1).path = fullfile(pathstr,name,filesep); % path of dirname
                        
                        % NB : series field is an empty @serie object at the creation of the exam
                        
                    end
                    idx_append = length(examArray);
                end
            end
            
        end % ctor
        % -----------------------------------------------------------------
        
    end
    
end % classdef
