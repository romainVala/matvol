function gen_scheme2siemens( dirpath, plt )
% GEN_SCHEME2SIEMENS Reads 'gen_scheme' output file ('dw_scheme.txt') from MRtrix3, show some
% stats, and print it with the righ formatting for Siemens sequence.
%
% SYNTAX
%   gen_scheme2siemens()               % opens a GUI to select directory
%   gen_scheme2siemens( dirpath )
%   gen_scheme2siemens( dirpath, plt ) % 2nd argument is for plotting (0 / 1)
%
% INPUT
%   dirpath : path of the directory containing 'dw_scheme.txt'
%   plot    : 0 / 1 , for figure plotting
%
%

fname = 'dw_scheme.txt';


%% load

if nargin < 1
    dirpath = uigetdir();
    if dirpath==0
        return
    end
end
if nargin < 2
    plt = 1;
end

fpath = fullfile(dirpath,fname);

dwischeme = load(fpath);


%% shortcuts

x = dwischeme(:,1);
y = dwischeme(:,2);
z = dwischeme(:,3);
b = dwischeme(:,4);


%% special case for b0

b0 = b == 0;
x(b0) = 0;
y(b0) = 0;
z(b0) = 0;


%% some stats

[u_b,u_b2a,u_b2c] = unique(b);

ndir = zeros(size(u_b));

for s = 1 : length(u_b)
    
    ndir(s) = sum(b == u_b(s));
    
end

disp(fpath)
disp('bval & ndir :')
disp([u_b,ndir]')
fprintf('total = %d\n', sum(ndir))


%% scale

max_b = max(b);

xs = x.*b/max_b;
ys = y.*b/max_b;
zs = z.*b/max_b;


%% split by shell for better plot

shell = struct;

for s = 1 : length(u_b)
    
    idx = u_b2c == s;
    
    shell(s).b = u_b(s);
    shell(s).x = xs(idx);
    shell(s).y = ys(idx);
    shell(s).z = zs(idx);
    
end


%% plot

if plt
    
    figH          = figure('Name',fpath,'NumberTitle','off');
    figH.UserData = mfilename;
    
    tg = uitabgroup(figH);
    
    % plot each shell seperatly
    for s = 1 : length(u_b)
        
        t = uitab(tg,'Title',sprintf('%3d x b%4d', ndir(s), u_b(s)));
        axes(t); %#ok<LAXES>
        
        ZEROS = zeros(size(shell(s).x));
        
        quiver3(ZEROS, ZEROS, ZEROS, shell(s).x, shell(s).y, shell(s).z)
        
        axis equal
        set(gca,'CameraViewAngle', 8)
        rotate3d on
        axis off
    end
    
    % plot all shells in a single figure
    t = uitab(tg,'Title',sprintf('all dirs (%d)', sum(ndir)));
    axes(t);
    hold on
    for s = 1 : length(u_b)
        
        ZEROS = zeros(size(shell(s).x));
        
        quiver3(ZEROS, ZEROS, ZEROS, shell(s).x, shell(s).y, shell(s).z)
        
    end
    axis equal
    set(gca,'CameraViewAngle', 8)
    rotate3d on
    view(3)
    axis off
    tg.SelectedTab = t; % focus on the last tab with all shells
    
end

%% print for siemens

fprintf('for the siemens diffusion vector text file :\n')
fprintf('********** from here **********\n')
fprintf('# intended for ndir/bval = ')
for s = 1 : length(u_b)
    if s ~= 1
        fprintf(' // ')
    end
    fprintf('%d x b%d', ndir(s), u_b(s))
end
fprintf('\n')
fprintf('[directions=%d]\n', sum(ndir))
fprintf('CoordinateSystem = xyz\n')
fprintf('Normalisation = none\n')
for d = 1 : sum(ndir)
    fprintf('Vector[%d] = ( %g, %g, %g )\n', d-1, xs(d), ys(d), zs(d) )
end
fprintf('********** to here **********\n')


end % end

