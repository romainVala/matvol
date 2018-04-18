function dir_out = r_mkdir(base_dir,new_dir)
% R_MKDIR creates directory in 'base_dir' whith the name 'new_dir'.
% This function can work with both strings and cellstrings, and will adapts
% it's behaviour according to the dimensions of the inputs.
%
%   example :
%         dir_out = r_mkdir(  'base_dir'                 ,  'new_dir'                )
%         dir_out = r_mkdir(  'base_dir'                 , {'new_dir_1','new_dir_2'} )
%         dir_out = r_mkdir( {'base_dir_1','base_dir_2'} ,  'new_dir'                )
%         dir_out = r_mkdir( {'base_dir_1','base_dir_2'} , {'new_dir_1','new_dir_2'} )
%
%
% See also r_movefile

%% Check input arguments

if nargin ~= 2
    error('base_dir & new_dir must be defined')
end

% Ensure the outputs are defined
dir_out = {};


%% Prepare inputs

% Ensure the inputs are cellstrings, to avoid dimensions problems
base_dir = cellstr(base_dir);
new_dir  = cellstr(new_dir);

% Repeat base_dir to match new_dir size
if numel(base_dir) == 1
    base_dir = repmat(base_dir,size(new_dir));
end

% Repeat new_dir to match base_dir size
if numel(new_dir) == 1
    new_dir = repmat(new_dir,size(base_dir));
end

% Assert the dimensions match
if any(size(base_dir)-size(new_dir))
    error('[%s]: the 2 cell input must have the same size',mfilename)
end


%% mkdir

for k=1:length(base_dir)
    
    dir_out{k,1} = [fullfile(base_dir{k},new_dir{k}) filesep]; %#ok<AGROW>
    
    if ~exist(dir_out{k},'dir')
        mkdir(dir_out{k});
    end
    
end


end % function
