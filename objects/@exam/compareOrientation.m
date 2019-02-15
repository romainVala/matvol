function varargout = compareOrientation( examArray, par )
% COMPAREORIENTATION
%
% Syntax = [ good, bad_orient, bad_dim ] = examArray.compareOrientation( serie_regex )
%                                          examArray.compareOrientation( serie_regex )
%
% All outputs are @exam arrays
%
% See also analyzeCountSeries


%% Check input arguments

if ~exist('par','var')
    par = ''; % for defpar
end

defpar.serie_regex = '.*';
defpar.verbose     = 1;

par = complet_struct(par,defpar);


%% Get the series

serieArray = examArray.getSerie(par.serie_regex);


%% Compare

good       = exam.empty;
bad_orient = exam.empty;
bad_dim    = exam.empty;

if numel(serieArray) ~= 0
    
    for ex = 1 : size(serieArray,1)
        
        orientation = zeros(6+3,size(serieArray,2));
        dim         = zeros(3,size(serieArray,2));
        
        for ser = 1 : size(serieArray,2)
            
            orientation(1:6,ser) = serieArray(ex,ser).sequence.ImageOrientationPatient; % 6 x 1
            orientation(  7,ser) = serieArray(ex,ser).sequence.sPositiondCor;
            orientation(  8,ser) = serieArray(ex,ser).sequence.sPositiondTra;
            orientation(  9,ser) = serieArray(ex,ser).sequence.sNormaldTra;
            dim(1,ser)           = serieArray(ex,ser).sequence.Rows;
            dim(2,ser)           = serieArray(ex,ser).sequence.Columns;
            dim(3,ser)           = serieArray(ex,ser).sequence.Slices;
            
        end
        
        orient_differs = any( any( abs( orientation - orientation(:,1) ) > 1e-6 ) );
        if orient_differs
            if par.verbose > 1
                fprintf('Orientation differs in \n%s\n', serieArray(ex,ser).exam.path)
                disp(orientation)
            end
            bad_orient(end+1) = examArray(ex); %#ok<AGROW>
        end
        
        dim_differs = any( any( abs( dim - dim(:,1) ) > 1e-3 ) );
        if dim_differs
            if par.verbose > 1
                fprintf('Dimension differs in \n%s\n', serieArray(ex,ser).exam.path)
                disp(dim)
            end
            bad_dim(end+1) = examArray(ex); %#ok<AGROW>
        end
        
        if orient_differs || dim_differs
            if par.verbose > 1
                fprintf('\n')
            end
        else
            good(end+1) = examArray(ex); %#ok<AGROW>
        end
        
    end
    
    % Sumup
    N            = numel(examArray);
    N_good       = numel(good);
    N_bad_orient = numel(bad_orient);
    N_bad_dim    = numel(bad_dim);
    if par.verbose > 0
        fprintf('good       N = %d/%d (%d%%)\n', N_good      , N, round(100*N_good      /N))
        fprintf('bad_orient N = %d/%d (%d%%)\n', N_bad_orient, N, round(100*N_bad_orient/N))
        fprintf('bad_dim    N = %d/%d (%d%%)\n', N_bad_dim   , N, round(100*N_bad_dim   /N))
        fprintf('\n')
    end
    
end


%% Output

if nargout > 0
    varargout        = {};
    varargout{end+1} = good;
    varargout{end+1} = bad_orient;
    varargout{end+1} = bad_dim;
end


end % function
