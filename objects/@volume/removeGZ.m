function removeGZ( volumeArray )
% REMOVEGZ removes .gz from each file name inside the volumeArray, if needed.


for vol = 1 : numel(volumeArray)
    
    for line = 1 : size(volumeArray(vol).name,1)
        
        if strcmp(volumeArray(vol).name(line,end-2:end),'.gz')
            volumeArray(vol).name(:,end-2:end) = [];
        end
        
    end % volume(i)
    
end % volume

end % function
