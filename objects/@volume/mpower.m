function [ interleavedVolArray ] = mpower( volArray_1, volArray_2 )
%MPOWER concatenates + interleave the two inputs
% Syntax : interleavedVolArray = volArray_1 ^ volArray_2

assert( numel(volArray_1) == numel(volArray_2) , '[InterleaveVolumeArray]: volumeArray must have the same numel' )

% Empty @volume array
interleavedVolArray = volume.empty;

for vol = 1 : numel(volArray_1)
    interleavedVolArray(end+1) = volArray_1(vol); %#ok<*AGROW>
    interleavedVolArray(end+1) = volArray_2(vol);
end

end % function
