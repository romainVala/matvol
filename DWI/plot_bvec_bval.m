function plot_bvec_bval( dwi_dir )
% PLOT_BVEC_BVAL will fetch .bvec and .bval files in a directory to plot
% them.
%
% If several directory are provided, several figures will be
% displayed, one fig per data set and one last fig with all datasets.
%
% SYNTAX
%
% plot_bvec_bval()           => a GUI will pop to select select dirs
% plot_bvec_bval( dwi_dir )  => dir(s) provided
%

%% Get dir graphically (if needed)

if nargin == 0
    
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


%% Plot

figH          = figure('Name',dwi_dir{1},'NumberTitle','off');
figH.UserData = mfilename;

tg = uitabgroup(figH);

for i = 1 : n_bvec
    
    t = uitab(tg,'Title',upper_dir_name{i});
    ax(i) = axes(t); %#ok<AGROW,LAXES>
    
    X = zeros( 1, size(bvec{i},2) ); % starting point of the arrow
    Y = zeros( 1, size(bvec{i},2) );
    Z = zeros( 1, size(bvec{i},2) );
    U = bvec{i}(1,:) .* bval{i}; % component in each direction
    V = bvec{i}(2,:) .* bval{i};
    W = bvec{i}(3,:) .* bval{i};
    
    quiver3(ax(i), X', Y', Z', U', V', W')
    
    hold(ax(i),'on')
    axis(ax(i),'equal')
    
end


%% Print in terminal a small histogram

norm_bvec = cell(n_bvec,1);
bval_approx = cell(size(n_bvec,1),1);
for i = 1 : n_bvec
    
    % print dataset name
    fprintf('%s \n', upper_dir_name{i});
    
    % Norm of bvec
    norm_bvec{i} = sqrt( bvec{i}(1,:).^2 + bvec{i}(2,:).^2 + bvec{i}(3,:).^2 );
    norm_bvec{i} = round(norm_bvec{i} * 1000) / 1000; % round it to 1/1000
    unique_norm  = unique( norm_bvec{i} );
    
    fprintf('vector unique norm (approx +-1/1000) = %s\n', num2str(unique_norm,'%1.3g '))
    
    % Histogram of bval
    bval_approx{i} = 100 * round(bval{i}/100);
    [unique_val] = unique( bval_approx{i} );
    hist_x = unique_val;
    hist_y = zeros(size(hist_x));
    for j = 1 : length(unique_val)
        hist_y(j) = sum( unique_val(j)==bval_approx{i} );
    end
    fprintf('bval unique (approx b=+-100) = %s \n', num2str(hist_x,'%d '))
    fprintf('bval ucount (approx b=+-100) = %s \n', num2str(hist_y,'%d '))
    
    fprintf('\n')
    
end


end % function
