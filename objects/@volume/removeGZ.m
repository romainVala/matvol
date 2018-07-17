function removeGZ( volumeArray )
% REMOVEGZ removes .gz from each file name inside the volumeArray, if needed.


for vol = 1 : numel(volumeArray)
    
    for lineNAME = 1 : size(volumeArray(vol).name,1)
        
        idxNAME = strfind(volumeArray(vol).name(lineNAME,:),'.gz');
        if ~isempty(idxNAME)
            volumeArray(vol).name(:,idxNAME:end) = [];
        end
        
    end % volume(i)
    
    for linePATH = 1 : size(volumeArray(vol).path,1)
        
        idxPATH = strfind(volumeArray(vol).path(linePATH,:),'.gz');
        if ~isempty(idxPATH)
            volumeArray(vol).path(:,idxPATH:end) = [];
        end
        
    end % volume(i)
    
end % volume

end % function
