function [ volumeArray ] = getVolumes( examArray, serie_regex, volume_regex )
% Syntax  : fetch the series.tag corresponfing to the serie_regex.
% Example : run_vol  = examArray.getVolumes('run' , 'f');
%           run1_vol = examArray.getVolumes('run1', '^rf$');
%           run2_vol = examArray.getVolumes('run2', 'rf');

AssertIsExamArray(examArray);

volumeArray = examArray.getSeries(serie_regex).getVolumes(volume_regex);

end % function
