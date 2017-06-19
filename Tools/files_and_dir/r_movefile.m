function dir_out = r_movefile(source,dest,type)
% R_MOVEFILE moves, copies, or links files/dirs
%
% *************************************************************************
%
% WARNING : if you need to create directories, prepare them with r_mkdir to
% avoid conflicts !
%
% This function DOES NOT make verifications to check if the destination
% dirs exists !
%
% *************************************************************************
%
%   type =
%       'move'  movefile
%       'copyn' copy without overwrite
%       'copy'  copy with    overwrite
%       'linkn' symbolic link without overwrite
%       'link'  symbolic link with    overwrite
%
%   example : syntax for 'source' and 'dest' is similar to r_mkdir
%
%
% See also r_mkdir

%% Check input arguments

if nargin < 3
    error('type is required explicitly : ''move'', ''copyn'', ''copy'', ''linkn'', ''link''')
end

if nargin < 2
    error('source & dest must be defined')
end

% Ensure the outputs are defined
dir_out = {};


%% Prepare inputs

% Ensure the inputs are cellstrings, to avoid dimensions problems
source = cellstr(source);
dest   = cellstr(dest);

% Repeat source to match dest size
if numel(source) == 1
    source = repmat(source,size(dest));
end

% Repeat dest to match source size
if numel(dest) == 1
    dest = repmat(dest,size(source));
end

% Assert the dimensions match
if any(size(source)-size(dest))
    error('[%s]: the 2 cell input must have the same size',mfilename)
end


%% movefile

[~, source_dir_name] = get_parent_path(source);

for idx = 1:length(source)
    
    for line = 1:size(source{idx},1) % in case of multilevel elements such as source={char(5,30);char(4,32);...}
        
        % In case the destination dir does not exists
        if exist(dest{idx},'dir')
            dir_out{idx}(line,:) = fullfile(dest{idx},source_dir_name{idx}(line,:)); %#ok<*AGROW>
        else
            dir_out{idx}(line,:) = dest{idx};
        end
        
        switch type
            case 'copyn'
                if ~exist(dir_out{idx}(line,:),'file')
                    cmd = sprintf('cp -fpr %s %s',source{idx}(line,:),dest{idx});
                    unix(cmd);
                end
                
            case 'copy'
                cmd = sprintf('cp -fpr %s %s',source{idx}(line,:),dest{idx});
                unix(cmd);
                
            case 'linkn'
                if ~exist(dir_out{idx}(line,:),'file')
                    cmd = sprintf('ln -s %s %s',source{idx}(line,:),dest{idx});
                    unix(cmd);
                end
                
            case 'link'
                cmd = sprintf('ln -s %s %s',source{idx}(line,:),dest{idx});
                unix(cmd);
                
            case 'move'
                movefile(deblank(source{idx}(line,:)),dest{idx});
                
            otherwise
                error('[%s]: type %s unknown',mfilename,type)
                
        end
        
    end
    
end


end % function
