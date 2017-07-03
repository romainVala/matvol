function jobs = job_coregister(src,ref,other,par)
% JOB_COREGISTER - SPM:Spatial:Coregister
%
% To build the image list easily, use get_subdir_regex & get_subdir_regex_files
%
% See also get_subdir_regex get_subdir_regex_files


%% Check input arguments

if ~exist('other','var'), other = {}             ; end
if isempty(other)       , other = {}             ; end
if ~iscell(other)       , other = cellstr(other)'; end
if ~iscell(src)         , src   = cellstr(src)   ; end
if ~iscell(ref)         , ref   = cellstr(ref)'  ; end

if ~exist('par','var')
    par = ''; % for defpar
end


%% defpar

defpar.type   = 'estimate';
defpar.interp = 1;
defpar.prefix = 'r';
defpar.sge    = 0;
defpar.redo   = 0;
defpar.run    = 0;
defpar.display= 0;

defpar.jobname  = 'spm_coreg';
defpar.walltime = '00:30:00';

par = complet_struct(par,defpar);


%% SPM:Spatial:Coregister

skip=[];
for nbsuj = 1:length(ref)
    %     if ~par.redo
    %         if is_hdr_realign(src(nbsuj)),  skip = [skip nbsuj];     fprintf('skiping suj %d becasue %s is realigned',nbsuj,src{nbsuj});       end
    %     end
    
    switch par.type
        case 'estimate'
            jobs{nbsuj}.spm.spatial.coreg.estimate.ref = ref(nbsuj); %#ok<*AGROW>
            jobs{nbsuj}.spm.spatial.coreg.estimate.source = src(nbsuj);
            if ~isempty(other)
                jobs{nbsuj}.spm.spatial.coreg.estimate.other = cellstr(other{nbsuj});
            end
            
            jobs{nbsuj}.spm.spatial.coreg.estimate.eoptions.cost_fun = 'nmi';
            jobs{nbsuj}.spm.spatial.coreg.estimate.eoptions.sep = [4 2];
            jobs{nbsuj}.spm.spatial.coreg.estimate.eoptions.tol = [0.02 0.02 0.02 0.001 0.001 0.001 0.01 0.01 0.01 0.001 0.001 0.001];
            jobs{nbsuj}.spm.spatial.coreg.estimate.eoptions.fwhm = [7 7];
            
        case 'estimate_and_write'
            
            jobs{nbsuj}.spm.spatial.coreg.estwrite.ref = ref(nbsuj);
            jobs{nbsuj}.spm.spatial.coreg.estwrite.source = src(nbsuj);
            if ~isempty(other)
                jobs{nbsuj}.spm.spatial.coreg.estwrite.other = cellstr(other{nbsuj});
            end
            
            jobs{nbsuj}.spm.spatial.coreg.estwrite.eoptions.cost_fun = 'nmi';
            jobs{nbsuj}.spm.spatial.coreg.estwrite.eoptions.sep = [4 2];
            jobs{nbsuj}.spm.spatial.coreg.estwrite.eoptions.tol = [0.02 0.02 0.02 0.001 0.001 0.001 0.01 0.01 0.01 0.001 0.001 0.001];
            jobs{nbsuj}.spm.spatial.coreg.estwrite.eoptions.fwhm = [7 7];
            
            jobs{nbsuj}.spm.spatial.coreg.estwrite.roptions.interp = par.interp;
            jobs{nbsuj}.spm.spatial.coreg.estwrite.roptions.wrap = [0 0 0];
            jobs{nbsuj}.spm.spatial.coreg.estwrite.roptions.mask = 0;
            jobs{nbsuj}.spm.spatial.coreg.estwrite.roptions.prefix = par.prefix;
            
        case 'write'
            
            jobs{nbsuj}.spm.spatial.coreg.write.ref = ref(nbsuj);
            jobs{nbsuj}.spm.spatial.coreg.write.source = cellstr(src{nbsuj});
            
            jobs{nbsuj}.spm.spatial.coreg.write.roptions.interp = par.interp;
            jobs{nbsuj}.spm.spatial.coreg.write.roptions.wrap = [0 0 0];
            jobs{nbsuj}.spm.spatial.coreg.write.roptions.mask = 0;
            jobs{nbsuj}.spm.spatial.coreg.write.roptions.prefix = par.prefix;
            
    end
    
end


%% Other routines

[ jobs ] = job_ending_rountines( jobs, skip, par );


end % function
