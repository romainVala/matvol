function [upper_dir_path, upper_dir_name, varargout] = get_parent_path(input_dir,level)
% GET_PARENT_PATH Perferforms a job similar to fileparts, but can do
% multiple levels
%
%   ***to be completed***
%

%% Check input arguments

% --- Level ---
if nargin < 2
    level = 1;
end
assert(isnumeric(level) && numel(level)==1 && round(level)==level, 'level mest be an integer')

% --- input_dir ---
if nargin < 1
    error('input_dir must be defined')
end

% Ensure the outputs are defined
upper_dir_path = {};
upper_dir_name = {};
varargout{1}   = {};


%% Recursive part

if level ~= 0
    
    concat = 0;
    
    if level < 0
        level  = abs(level);
        concat = 1;
    end
    
    upper_dir_path = input_dir;
    
    for lvl = 1:level
        
        % Recursivity
        [upper_dir_path, upper_dir_name] = get_parent_path(upper_dir_path, 0);
        
        if (nargout-1>lvl)
            varargout{nargout-1-lvl} = upper_dir_name;
        end
        
        if concat
            
            if lvl > 1
                for nbs = 1:length(upper_dir_name)
                    %upper_dir_name{nbs} = [upper_dir_name{nbs} '_' sub_dir_mem{nbs}];
                    upper_dir_name{nbs} = cat(2,upper_dir_name{nbs},sub_dir_mem{nbs});
                end
            end
            
            sub_dir_mem = upper_dir_name;
            
        end
        
    end
    
    return
    
end


%% Main process : use fileparts over each input_dir

makeitchar = 0;
if ischar(input_dir)
    input_dir  = cellstr(input_dir);
    makeitchar = 1;
end

for lvl=1:length(input_dir)
    
    for idx = 1:size(input_dir{lvl},1)
        
        [pathstr,name,extension] = fileparts( input_dir{lvl}(idx,:) );
        
        if isempty(name) %when the path end with \
            [pathstr,name] = fileparts(pathstr);
        end
        
        % upper_dir_path{lvl} = pathstr ;
        dirpath{idx} = pathstr; 
        %i need it for process mrtrix
        if ~isempty(extension)
            name=[name extension];
        end
        
        % upper_dir_name{lvl}(idx,:) = name;
        dirname{idx} = name;
        
    end
    
    upper_dir_path{lvl,1} = char(dirpath);
    upper_dir_name{lvl,1} = char(dirname);
    
    dirpath = {}; %#ok<*AGROW>
    dirname = {};
    
end

if makeitchar
    upper_dir_name = char(upper_dir_name);
    upper_dir_path = char(upper_dir_path);
end


end % function
