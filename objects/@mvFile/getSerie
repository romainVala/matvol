function serieArray = getSerie( mvFileArray )
%GETSERIE output is a @serie array, with the same dimension as volumeArray

serieArray = serie.empty;

for i = 1 : numel(mvFileArray)
    serieArray(i) = mvFileArray(i).serie; % !!! this is a pointer copy, not a deep copy
end

serieArray = reshape(serieArray, size(mvFileArray));

end % function
