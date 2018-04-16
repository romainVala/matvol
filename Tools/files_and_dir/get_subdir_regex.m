function [output, not_found] = get_subdir_regex(indir, reg_ex, varargin)
% GET_SUBDIR_REGEX function fetch directory names recursivly according the
% regular expression.
%
%   Syntax :
%       dirs = get_subdir_regex(baseDirectory, reg_ex1, reg_ex2, reg_ex3, ...)
%
%   Exemple :
%       anatomical_Dirs = get_subdir_regex('project_Path','subjectName_RegularExpression','anatomicalDir_RegularExpression')
%
%
%   Note :
%         If one regexp has a '-' at the begining, the regexp after the '-'
%         will be correctly detected, but not included in the output list.
%
% See also get_subdir_regex_multi regexp


%% Check input arguments

if nargin < 2
    reg_ex=('graphically');
end

if nargin < 1
    indir = pwd;
end

% Ensure the outputs are defined
output={};
not_found={};


%% Recursive part

if ~isempty(varargin)
    
    output = get_subdir_regex(indir, reg_ex); % do the first arguments before
    for nArgIn = 1:length(varargin)
        output = get_subdir_regex(output, varargin{nArgIn}); % Then do the other arguments
    end
    
    return
    
end


%% Output organization


if ~iscell(indir), indir={indir};end


% --- Graphically ? -------------------------------------------------------
if ischar(reg_ex) && strcmp(reg_ex,'graphically')
    
    output={};
    
    for nb_dir = 1:length(indir)
        
        % Graphic interface from SPM
        dir_sel = spm_select(inf,'dir','Select directories','',indir{nb_dir});
        dir_sel = cellstr(dir_sel);
        
        % Add the graphically selected dirs into the output
        for d = 1:length(dir_sel)
            output{end+1,1} = dir_sel{d}; %#ok<AGROW>
        end
        
    end
    
    return
    
end


if ~iscell(reg_ex), reg_ex={reg_ex};end


% --- Using the regular expressions ---------------------------------------
for nb_dir = 1:length(indir)
    
    dir_content = dir(indir{nb_dir}); % fetch dir content
    dir_content = dir_content(3:end); % the first two elements are always "." and ".."
    
    found_subdir = 0;
    
    for d = 1:length(dir_content)
        
        for nb_reg = 1:length(reg_ex)
            
            % Trick : recognized a dir, but do not include it in the output list
            if strcmp(reg_ex{nb_reg}(1),'-')
                if dir_content(d).isdir && ~isempty(regexp(dir_content(d).name,reg_ex{nb_reg}(2:end), 'once'))
                    break % to avoid that 2 reg_ex adds the same dir
                end
            end
            
            if dir_content(d).isdir && ~isempty(regexp(dir_content(d).name,reg_ex{nb_reg}, 'once'))
                output{end+1,1} = fullfile(indir{nb_dir},dir_content(d).name,filesep); %#ok<AGROW>
                found_subdir = 1;
                break % to avoid that 2 reg_ex adds the same dir
            end
            
        end
        
    end
    
    if ~found_subdir
        not_found{end+1} = indir{nb_dir}; %#ok<AGROW>
    end
    
end


end % function
