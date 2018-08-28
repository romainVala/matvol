function [slice_order,ref_slice] = get_slice_order(parameters,nbslices)
%to determine slice order and reference slice
%used by do_slice_timing and lcogn_single_firstlevel (for microtime onnset and bins)


if isfield(parameters.slicetiming,'user_reference_slice') && ...
        isfield(parameters.slicetiming,'user_slice_order')
    ref_slice= parameters.slicetiming.user_reference_slice;
    slice_order = parameters.slicetiming.user_slice_order;
else
    
    
    switch parameters.slicetiming.slice_order
        case 'sequential_ascending'
            slice_order = 1:1:nbslices;
            if strcmp(parameters.slicetiming.reference_slice,'first'),ref_slice=1;
            else,ref_slice = floor(nbslices/2); end
            
        case 'sequential_descending'
            slice_order = nbslices:-1:1;
            if strcmp(parameters.slicetiming.reference_slice,'first'),ref_slice=nbslices;
            else,ref_slice = floor(nbslices/2); end
            
        case 'interleaved_ascending'
            
            if mod(nbslices,2) %odd slice number
                slice_order = [1:2:nbslices 2:2:nbslices] ;
                if strcmp(parameters.slicetiming.reference_slice,'first'),ref_slice=1;
                else,ref_slice = 2; end
                
            else
                slice_order = [2:2:nbslices 1:2:nbslices] ;
                if strcmp(parameters.slicetiming.reference_slice,'first'),ref_slice=2;
                else,ref_slice = 1; end
                
            end
            
        case 'interleaved_descending'
            for k=1:nbslices
                %to be done	slice_order(k) = round((nbslices-k)/2 + (rem((nbslices-k),2) * (nbslices - 1)/2)) + 1;
            end
            
        otherwise
            if length(slice_ord) ~= nslices
                sprintf('nbslices (%d) and length(slice_order) (%d) differ',nbslices,length(slice_order));
            end
            error('Slice Timing failed.');
    end
end
