function [ volumeArray ] = getVolumes( serieArray, regex )
% Syntax  : fetch the series corresponfing to the regex.
% Example : run_volumes  = serieArray.getVolumes('run');
%           run1_volumes = serieArray.getVolumes('run1');
%           run2_volumes = serieArray.getVolumes('run2');

AssertIsSerieArray(serieArray);

if nargin < 2
    regex = '.*';
end

volumeArray = volume.empty;

for ex = 1 : size(serieArray,1)
    
    for ser = 1 : size(serieArray,2)
        
        counter = 0;
        
        for vol = 1 : numel(serieArray(ex,ser).volumes)
            
            if ...
                    ~isempty(serieArray(ex,ser).volumes(vol).tag) && ...                 % tag is present in the @volume ?
                    ~isempty(regexp(serieArray(ex,ser).volumes(vol).tag, regex, 'once')) % found a corresponding volume.tag to the regex ?
                
                counter = counter + 1;
                volumeArray(ex,ser,counter) = serieArray(ex,ser).volumes(vol);
                
            end
            
        end % vol in serie
        
    end % serie in exam
    
end % exam

end % function
