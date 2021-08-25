function n = numel( mvArray )
% NUMEL total numeber of elemets

n = prod(size(mvArray)); %#ok<PSIZE>
% can't use the built-in numel

end % function
