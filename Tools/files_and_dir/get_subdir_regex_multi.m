function [output, not_found] = get_subdir_regex_multi(indir, reg_ex, varargin)
% GET_SUBDIR_REGEX_MULTI do a get_subdir_regex over all dirs in indir={'dir1';'dir2'}
%
%   Exemple :
%       anatomical_Dirs = get_subdir_regex({'longitudinal_1_Path';'longitudinal_2_Path'},'subjectName_RegularExpression','anatomicalDir_RegularExpression')
%
%
% See also get_subdir_regex


%% Check input arguments

if nargin < 1
    error('indir is not defined')
end

if nargin < 2
    error('reg_ex is not defined')
end

if ~isempty(varargin)
    error('Check it  !! not tested c rrr')
end

% Ensure the outputs are defined
output={};
not_found={};


%% Do the get_subdir_regex over all the 'indir'

for d = 1:length(indir)
    [output{d,1}, not_found{d,1}] = get_subdir_regex(indir(d),reg_ex); %#ok<AGROW>
end


end % function
