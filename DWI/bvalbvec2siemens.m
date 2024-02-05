function bvalbvec2siemens( dwi_dir, tolerance )
% BVALBVEC2SIEMENS will fetch .bvec and .bval files in a directory and generate .dvs file for Siemens
%
% SYNTAX
%
% plot_bvec_bval()                      => a GUI will pop to select select dirs
% plot_bvec_bval( dwi_dir )             => dir(s) provided
% plot_bvec_bval( dwi_dir, tolerance )  => tolerance provided
%

if nargin < 2
    tolerance = 100; % bvalue tolerance
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


%% Load

bvec = cell(size(n_bvec,1),1);
bval = cell(size(n_bvec,1),1);

for i = 1 : n_bvec

    bvec{i} = load( deblank(bvec_file(i,:)) );
    bval{i} = load( deblank(bval_file(i,:)) );

end


%% Print in terminal a small histogram

norm_bvec   = cell(n_bvec,1);
bval_approx = cell(size(n_bvec,1),1);
hist_x      = cell(n_bvec,1);
hist_y      = cell(n_bvec,1);

for i = 1 : n_bvec

    % print dataset name
    fprintf('%s \n', upper_dir_name{i});

    % Norm of bvec
    norm_bvec{i} = sqrt( bvec{i}(1,:).^2 + bvec{i}(2,:).^2 + bvec{i}(3,:).^2 );
    norm_bvec{i} = round(norm_bvec{i} * 1000) / 1000; % round it to 1/1000
    unique_norm  = unique( norm_bvec{i} );

    fprintf('vector unique norm (approx +-1/1000) = %s\n', num2str(unique_norm,'%1.3g '))

    % Histogram of bval
    bval_approx{i} = tolerance * round(bval{i}/tolerance);
    unique_val = unique( bval_approx{i} );
    hist_x{i} = unique_val;
    hist_y{i} = zeros(size(hist_x));
    for j = 1 : length(unique_val)
        hist_y{i}(j) = sum( unique_val(j)==bval_approx{i} );
    end
    fprintf('bval unique (approx b=+-%d) = %s \n', tolerance, num2str(hist_x{i},'%d '))
    fprintf('bval ucount (approx b=+-%d) = %s \n', tolerance, num2str(hist_y{i},'%d '))

    fprintf('\n')

end


%% Write .dvs file

% prepare filename
str = '';
for i = 1 : n_bvec
    for j = 1 : length(hist_x{i})
        str = sprintf('%s%dxb%d', str, hist_y{i}(j), hist_x{i}(j));
        if j < length(hist_x{i})
            str = sprintf('%s+', str);
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
    for j = 1 : length(hist_x{i})
        if j ~= 1
            fprintf(fid,' // ');
        end
        fprintf(fid,'%d x b%d', hist_y{i}(j), hist_x{i}(j));
    end
    fprintf(fid,'\n');
    fprintf(fid,'[directions=%d]\n', length(bval{i}));
    fprintf(fid,'CoordinateSystem = xyz\n');
    fprintf(fid,'Normalisation = none\n');
    for d = 1 : length(bval{i})
        fprintf(fid,'Vector[%d] = ( %g, %g, %g )\n', d-1, bvec{i}(1,d), bvec{i}(2,d), bvec{i}(3,d) );
    end
    fprintf(fid,'\n');
end

% dont forget to close file
fclose(fid);


end % function
