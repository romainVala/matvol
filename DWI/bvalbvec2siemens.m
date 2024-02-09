function bvalbvec2siemens( dwi_dir, tolerance )
% BVALBVEC2SIEMENS will fetch .bvec and .bval files in each directory and
% generate a single .dvs (diffusion vector set) for Siemens magnets.
%
% SYNTAX
%   plot_bvec_bval()                      => a SPM GUI will pop to select dirs
%   plot_bvec_bval( dwi_dir )             => dir(s) provided
%   plot_bvec_bval( dwi_dir, tolerance )  => tolerance provided
%
% NOTES
%   `tolerance` is used to smooth the b-values interpretation : usually
%   when you ask on the magnet for bval=2000, you will get a value like
%   1990 or 2005. Other exemple : when you ask for bval=0, you will get 5.
%
% See also plot_bvec_bval, plot_dwi_vectors_siemens, gen_scheme2siemens

if nargin < 2
    tolerance = 50; % bvalue tolerance
end


%% Get dir graphically (if needed)

if nargin < 1

    dwi_dir = cfg_getfile([0 Inf],'dir'); % use SPM batch function to select dirs with a GUI
    if isempty(dwi_dir)
        fprintf('[%s]: no dir selected', mfilename)
    end

end

dwi_dir = cellstr(dwi_dir); % make sure its a cellstr (easier to manage later)
n_dir = length(dwi_dir);
[~, upper_dir_name] = get_parent_path(dwi_dir);


%% Fetch .bvec & .bval files

bvec_file = spm_select('FPList',dwi_dir,'.*bvec$');
bval_file = spm_select('FPList',dwi_dir,'.*bval$');

n_bvec = size(bvec_file,1);
n_bval = size(bval_file,1);

assert( n_bvec==n_bval && n_bvec==n_dir, 'found %d bvec and %d bval files in %d dirs', n_bvec, n_bval, n_dir )

data = struct;


%% Load

for i = 1 : n_bvec

    data(i).bvec = load( deblank(bvec_file(i,:)) );
    data(i).bval = load( deblank(bval_file(i,:)) );

end


%% Print in terminal a small histogram

for i = 1 : n_bvec

    % print dataset name
    fprintf('%s \n', upper_dir_name{i});

    % Norm of bvec
    data(i).norm_bvec = sqrt(  data(i).bvec(1,:).^2 +  data(i).bvec(2,:).^2 +  data(i).bvec(3,:).^2 );
    data(i).norm_bvec = round( data(i).norm_bvec * 1000) / 1000; % round it to 1/1000
    data(i).unique_norm  = unique(  data(i).norm_bvec );

    fprintf('vector unique norm (approx +-1/1000) = %s\n', num2str(data(i).unique_norm,'%1.3g '))

    % Histogram of bval
    data(i).bval_approx = tolerance * round(data(i).bval/tolerance);
    data(i).norm_bval   = data(i).bval_approx / max(abs(data(i).bval_approx));
    data(i).unique_val  = unique( data(i).bval_approx );
    data(i).hist_x = data(i).unique_val;
    data(i).hist_y = zeros(size(data(i).hist_x));
    for j = 1 : length(data(i).unique_val)
        data(i).hist_y(j) = sum( data(i).unique_val(j)==data(i).bval_approx );
    end
    fprintf('bval unique (approx b=+-%d) = %s \n', tolerance, num2str(data(i).hist_x,'%d '))
    fprintf('bval ucount (approx b=+-%d) = %s \n', tolerance, num2str(data(i).hist_y,'%d '))

    fprintf('\n')

end


%% Write .dvs file

% prepare filename
str = '';
for i = 1 : n_bvec
    for j = 1 : length(data(i).hist_x)
        str = sprintf('%s%db%d', str, data(i).hist_y(j), data(i).hist_x(j));
        if j < length(data(i).hist_x)
            str = sprintf('%s-', str);
        else
            if i < n_bvec
                str = sprintf('%s_', str);
            end
        end
    end
end

fname = sprintf('%s_%s_%s', mfilename, datestr(now,29) , str);
dvs_fpath = [fullfile(pwd, fname) '.dvs'];

% open file in write mode
fid = fopen(dvs_fpath, 'w', 'native', 'UTF-8');
assert(fid>0, 'could not open file %s', dvs_fpath)
fprintf('writing file : %s \n', dvs_fpath)

% fill file content
fprintf(fid,'# generation info : %s \n\n', dvs_fpath);
for i = 1 : n_bvec
    fprintf(fid,'# intended for ndir/bval = ');
    for j = 1 : length(data(i).hist_x)
        if j ~= 1
            fprintf(fid,' - ');
        end
        fprintf(fid,'%db%d', data(i).hist_y(j), data(i).hist_x(j));
    end
    fprintf(fid,'\n');
    fprintf(fid,'# on Diff card set b-value to b=%d \n', max(data(i).bval));
    fprintf(fid,'[directions=%d]\n', length(data(i).bval));
    fprintf(fid,'CoordinateSystem = xyz\n');
    fprintf(fid,'Normalisation = none\n');
    for d = 1 : length(data(i).bval)
        fprintf(fid,'Vector[%d] = ( %g, %g, %g )\n', d-1, ...
            data(i).bvec(1,d)*sqrt(data(i).norm_bval(d)), ...
            data(i).bvec(2,d)*sqrt(data(i).norm_bval(d)), ...
            data(i).bvec(3,d)*sqrt(data(i).norm_bval(d)));
    end
    fprintf(fid,'\n');
end

% dont forget to close file
fclose(fid);


%% Perform check

plot_dwi_vectors_siemens(dvs_fpath)


end % function
