function [ volumeArray ] = getVolumes( examArray, serie_regex, volume_regex, volume_type )
% Syntax  : fetch the volume_regex volume.(volume_type) corresponfing to the serie_regex, scanning the defined property.
% Example : run_vol  = examArray.getVolumes('run' , 'f'           );
%           run1_vol = examArray.getVolumes('run1', '^rf$'        );
%           run2_vol = examArray.getVolumes('run2', 'rf'          );
%           anat_vol = examArray.getVolumes('anat', 't1mpr','name');

%% Check inputs

AssertIsExamArray(examArray);

if nargin < 2
    serie_regex = '.*';
end

if nargin < 3
    volume_regex = '.*';
end

if nargin < 4
    volume_type = 'tag';
end


%% getVolumes from @exam

volumeArray = examArray.getSeries(serie_regex).getVolumes(volume_regex,volume_type);


end % function
