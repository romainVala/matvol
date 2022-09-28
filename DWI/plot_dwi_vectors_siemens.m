function plot_dwi_vectors_siemens( fpath_DiffusionVectors )
% PLOT_DWI_VECTORS_SIEMENS will plot all diffusion vectors set contained in the file
%
% SYNTAX
%
% plot_dwi_vectors_siemens()                          => a GUI will pop to select a file
% plot_dwi_vectors_siemens( fpath_DiffusionVectors )  => file is provided
%

%% Get dir graphically (if needed)

if nargin == 0
    
    fpath_DiffusionVectors = cfg_getfile([0 1],'any'); % use SPM batch function to select dirs with a GUI
    if isempty(fpath_DiffusionVectors)
        fprintf('[%s]: no file selected', mfilename)
    end
    
end

fpath_DiffusionVectors = char(fpath_DiffusionVectors); % make sure its a cellstr (easier to manage later)


%% Load

content = get_file_content_as_char(fpath_DiffusionVectors);
lines = strsplit(content,sprintf('\n'))';


%% Parse

idx_set_start = find(~cellfun('isempty', regexp(lines, '^\[directions=\d+\]')));
assert(~isempty(idx_set_start), 'no direction set found, or bad syntax')

set = struct;
for iset = 1 : length(idx_set_start)
    if iset~= length(idx_set_start)
        set(iset).line_idx_min = idx_set_start(iset  );
        set(iset).line_idx_max = idx_set_start(iset+1);
    else
        set(iset).line_idx_min = idx_set_start(iset  );
        set(iset).line_idx_max = length(lines);
    end
    raw_set_content = lines(set(iset).line_idx_min : set(iset).line_idx_max-1);
    set(iset).raw_set_content = raw_set_content;
    
    % directions
    result = regexp( raw_set_content, '^\[directions=(\d+)\]', 'tokens' );
    line_number = find(~cellfun('isempty',result));
    if isempty(line_number) || length(line_number) > 1
        error('bad syntax ?')
    end
    set(iset).directions = str2double(result{line_number}{1});
    
    % CoordinateSystem
    result = regexp( raw_set_content, '^CoordinateSystem\s?=\s?(\w+)', 'tokens' );
    line_number = find(~cellfun('isempty',result));
    if isempty(line_number) || length(line_number) > 1
        warning('bad syntax CoordinateSystem for dir=%d ?', set(iset).directions)
    end
    set(iset).CoordinateSystem = char(result{line_number}{1});
    
    % Normalisation
    result = regexp( raw_set_content, '^Normalisation\s?=\s?(\w+)', 'tokens' );
    line_number = find(~cellfun('isempty',result));
    if isempty(line_number) || length(line_number) > 1
        warning('bad syntax Normalisation for dir=%d ?', set(iset).directions)
    end
    set(iset).Normalisation = char(result{line_number}{1});
    
    % Vector
    pattern = '(\t?.*\t?)';
    result = regexp( raw_set_content, ['^Vector\[(\d+)\]\s*=\s*\(' pattern ',' pattern ',' pattern '\)'], 'tokens' );
    line_number = find(~cellfun('isempty',result));
    n_vect_detected = length(line_number);
    if isempty(line_number) || n_vect_detected~=set(iset).directions
        warning('bad syntax Vector for dir=%d ?', set(iset).directions)
        set(iset).is_ok = 0;
    else
        set(iset).is_ok = 1;
    end
    mx = nan(n_vect_detected,4);
    for v = 1 : n_vect_detected
        mx(v,:) = str2double(result{line_number(v)}{1});
    end
    set(iset).Vector = mx;
    
end


%% Plot

figH          = figure('Name',fpath_DiffusionVectors,'NumberTitle','off');
figH.UserData = mfilename;

tg = uitabgroup(figH);

for iset = 1 : length(set)
    
    t = uitab(tg,'Title',num2str(set(iset).directions));
    
    if set(iset).is_ok
        
        ax(iset) = axes(t); %#ok<AGROW,LAXES>
        mx = set(iset).Vector;
        X = zeros( size(mx,1), 1 ); % starting point of the arrow
        Y = zeros( size(mx,1), 1 );
        Z = zeros( size(mx,1), 1 );
        U = mx(:,2);
        V = mx(:,3);
        W = mx(:,4);
        
        quiver3(ax(iset), X', Y', Z', U', V', W')
        
        hold(ax(iset),'on')
        axis(ax(iset),'equal')
        
    end
    
end


%% Print in terminal some stats

for iset = 1 : length(set)
    
    if set(iset).is_ok
        
        mx = set(iset).Vector;
    
        X = mx(:,2);
        Y = mx(:,3);
        Z = mx(:,4);
        
        NORM = sqrt(X.^2 + Y.^2 + Z.^2);
        NORM = round(NORM*10)/10; % round it to 1/10
        
        % histogram
        unique_NORM  = unique( NORM );
        hist_x = unique_NORM;
        hist_y = zeros(size(hist_x));
        for j = 1 : length(unique_NORM)
            hist_y(j) = sum( unique_NORM(j)==NORM );
        end
        fprintf('[directions=%d]\n', set(iset).directions)
        fprintf('bval unique (approx b=+-100) = %s \n', num2str(hist_x','%g\t'))
        fprintf('bval ucount (approx b=+-100) = %s \n', num2str(hist_y','%d\t'))
        
        fprintf('\n')
        
    end
    
end


end % function
