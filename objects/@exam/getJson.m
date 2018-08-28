function [ jsonArray ] = getJson( examArray, serie_regex, json_regex, json_type )
% Syntax  : fetch the json_regex json.(json_type) corresponfing to the serie_regex, scanning the defined property.
% Example : run_vol  = examArray.getJson('run' , 'f'           );
%           run1_vol = examArray.getJson('run1', '^rf$'        );
%           run2_vol = examArray.getJson('run2', 'rf'          );
%           anat_vol = examArray.getJson('anat', 't1mpr','name');

%% Check inputs

if nargin < 2
    serie_regex = '.*';
end

if nargin < 3
    json_regex = '.*';
end

if nargin < 4
    json_type = 'tag';
end


%% getJson from @exam

jsonArray = examArray.getSerie(serie_regex).getJson(json_regex,json_type);


end % function
