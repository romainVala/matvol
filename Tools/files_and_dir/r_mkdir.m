function dir_out = r_mkdir(base_dir,new_dir_name)
% R_MKDIR creates directory in 'base_dir' whith the name 'new_dir_name'.
% This function can work with both strings and cellstrings, and will adapts
% it's behaviour according to the dimensions of the inputs.
% 
%   example :
%         dir_out = r_mkdir(  'base_dir'                 ,  'new_dir_name'                     )
%         dir_out = r_mkdir(  'base_dir'                 , {'new_dir_name_1','new_dir_name_2'} )
%         dir_out = r_mkdir( {'base_dir_1','base_dir_2'} ,  'new_dir_name'                     )
%         dir_out = r_mkdir( {'base_dir_1','base_dir_2'} , {'new_dir_name_1','new_dir_name_2'} )


%% Check input arguments

if nargin ~= 2
    error('base_dir & new_dir_name must be defined')
end

% Ensure the outputs are defined
dir_out = {};


%% Prepare inputs

% Ensure the inputs are cellstrings, to avoid dimensions problems
base_dir     = cellstr(base_dir);
new_dir_name = cellstr(new_dir_name);

% Repeat base_dir to match new_dir_name size
if numel(base_dir) == 1
    base_dir = repmat(base_dir,size(new_dir_name));
end

% Repeat new_dir_name to match base_dir size
if numel(new_dir_name) == 1
    new_dir_name = repmat(new_dir_name,size(base_dir));
end

% Assert the dimensions match
if any(size(base_dir)-size(new_dir_name))
    error('[%s]: the 2 cell input must have the same size',mfilename)
end


%% mkdir

for k=1:length(base_dir)
    
    dir_out{k} = [fullfile(base_dir{k},new_dir_name{k}) filesep]; %#ok<AGROW>
    
    if ~exist(dir_out{k},'dir')
        mkdir(dir_out{k});
    end
    
end


end % function
