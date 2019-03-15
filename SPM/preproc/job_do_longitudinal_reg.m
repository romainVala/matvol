function  jobs = job_do_longitudinal_reg(img,timeline,index_grouping,par)
%
% INPUT : img can be 'char' of volume(file), single-level 'cellstr' of volume(file), '@volume' array
%
% for spm12 segment, if img{nbsuj} has several line then it is a multichannel
%
%


%% Check input arguments

if ~exist('par', 'var')
    par='';
end

if nargin < 1
    help(mfilename)
    error('[%s]: not enough input arguments - image list is required',mfilename)
end

obj = 0;
if isa(img,'volume')
    obj = 1;
    in_obj  = img;
elseif ischar(img) || iscellstr(img)
    % Ensure the inputs are cellstrings, to avoid dimensions problems
    img = cellstr(img)';
else
    error('[%s]: wrong input format (cellstr, char, @volume)', mfilename)
end


%% defpar

defpar.cat12 = 0 ; % if non 0 it will perform the cat12 longitudinal registration
defpar.auto_add_obj = 1;

defpar.run     = 0;
defpar.display = 0;
defpar.redo    = 0;
defpar.sge     = 0;

defpar.jobname  = 'spm_longitudinal';
defpar.walltime = '02:00:00';

par = complet_struct(par,defpar);

defpar.matlab_opt = ' -nodesktop ';


par = complet_struct(par,defpar);

% Security
if par.sge
    par.auto_add_obj = 0;
end


%% Prepare job generation

% unzip volumes if required
if obj
    in_obj.unzip(par);
    img = in_obj.toJob;
else
    if ~iscell(img)
        img = cellstr(img);
    end
    img = unzip_volume(img);
end


%% Prepare job

skip=[];
tot_number_suj = max(index_grouping);

for nbsuj = 1:tot_number_suj
    ii = find(index_grouping == nbsuj);
    if par.cat12
        jobs{nbsuj}.spm.tools.cat.tools.series.data = img(ii);
        jobs{nbsuj}.spm.tools.cat.tools.series.bparam = 1000000;

    else
        jobs{nbsuj}.spm.tools.longit{1}.series.vols = img(ii);
        jobs{nbsuj}.spm.tools.longit{1}.series.times = timeline(ii);
        jobs{nbsuj}.spm.tools.longit{1}.series.noise = NaN;
        jobs{nbsuj}.spm.tools.longit{1}.series.wparam = [0 0 100 25 100];
        jobs{nbsuj}.spm.tools.longit{1}.series.bparam = 1000000;
        jobs{nbsuj}.spm.tools.longit{1}.series.write_avg = 1;
        jobs{nbsuj}.spm.tools.longit{1}.series.write_jac = 0;
        jobs{nbsuj}.spm.tools.longit{1}.series.write_div = 1;
        jobs{nbsuj}.spm.tools.longit{1}.series.write_def = 0;
    end
end

[ jobs ] = job_ending_rountines( jobs, skip, par );


%% Add outputs objects

if obj && par.auto_add_obj && par.run
    fprintf('TODO OOOOUUUU');
end

end % function
