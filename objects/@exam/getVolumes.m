function [ volumeArray ] = getVolumes( examArray, serie_regex, volume_regex )
% Syntax  : fetch the series.tag corresponfing to the serie_regex.
% Example : run_vol  = examArray.getVolumes('run' , 'f');
%           run1_vol = examArray.getVolumes('run1', '^rf$');
%           run2_vol = examArray.getVolumes('run2', 'rf');


%% Check inputs

AssertIsExamArray(examArray);

if nargin < 2
    serie_regex  = '.*';
end

if nargin < 3
    volume_regex = '.*';
end


%% getVolumes from @exam

volumeArray = examArray.getSeries(serie_regex).getVolumes(volume_regex);


end % function
